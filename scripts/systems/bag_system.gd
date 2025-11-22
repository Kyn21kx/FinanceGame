extends Node
class_name BagSystem # TODO: Rename to something like object interaction system

const THROWABLE_DETECTION_RADIUS_SQR := 10 * 10

var players_query := Query.new()
var bags_query := Query.new()
var throwables_query := Query.new()
var magnetizers_query := Query.new()
var magnetic_attracted_query := Query.new()

@export
var object_drag_strength: float

@export
var object_drag_length: float

func _ready() -> void:
	self.players_query.with_and_register(Components.Player.get_type_name())
	self.players_query.with_and_register(Components.Controller.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.players_query.with_and_register(Components.Thrower.get_type_name())

	self.bags_query.with_and_register(Components.Bag.get_type_name())
	self.bags_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.throwables_query.with_and_register(Components.Throwable.get_type_name())
	self.throwables_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.magnetizers_query.with_and_register(Components.MagneticAttracter.get_type_name())
	self.magnetizers_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.magnetic_attracted_query.with_and_register(Components.MagneticTarget.get_type_name())
	self.magnetic_attracted_query.with_and_register(Components.PhysicsBody.get_type_name())

	
func _process(_delta: float):
	self.players_query.each(_throwing_system_input)
	pass

func calculate_aim(controller: Components.Controller, player_pos: Vector3, throwable_pos: Vector3) -> Vector3:
	# Get the movement axis and apply that as the throwing direction if we want to throw
	var direction := controller.get_axis_left()

	# Awful by reference trick
	var result_wrapper : Array = [Vector3(direction.x, 0, direction.y)] # Z and X

	# If the object is close to and the direction's normal is sufficently angled to
	# the bag, we set the throwing direction in the direction of the bag so that it hits it
	self.bags_query.each(func iter(_bag_entity: RID, components: Array):
		var bag_body : Components.PhysicsBody = components[1]
		var bag_pos : Vector3 = bag_body.get_transform().origin
		const auto_aim_threshold_sqr := 90
		var diff : Vector3 = bag_pos - player_pos
		var direction_similarity : float = result_wrapper[0].dot(diff)
		print("direction similarity: ", direction_similarity)
		if (diff.length_squared() > auto_aim_threshold_sqr || direction_similarity  < 0.8):
			return
		result_wrapper[0] = (bag_pos - throwable_pos).normalized()
	)

	return result_wrapper[0]

func _throw_object(throwable_info: Components.Throwable, player_xform: Transform3D, throwable_xform: Transform3D, controller: Components.Controller, thrower_info: Components.Thrower):
	thrower_info.throwing_direction = self.calculate_aim(controller, player_xform.origin, throwable_xform.origin) # Handles auto aim when close to the bag
	throwable_info.state = Components.ThrowableState.Thrown
	

func _throwing_system_input(player: RID, components: Array):
	var controller : Components.Controller = components[1]
	var player_body : Components.PhysicsBody = components[2]
	var thrower_info : Components.Thrower = components[3]
	var player_xform = player_body.get_transform()
	self.throwables_query.each(func _iter_throwables(throwable: RID, throwable_comps: Array):
		if (throwable == player):
			# Players are throwable, so, let's avoid hitting ourselves
			return
		# Do a distance check and if it is close enough trigger the 
		var throwable_info : Components.Throwable = throwable_comps[0]
		var throwable_body : Components.PhysicsBody = throwable_comps[1]
		var throwable_xform := throwable_body.get_transform()
	
		var distance_sqr := throwable_xform.origin.distance_squared_to(player_xform.origin)
		DebugDraw3D.draw_text((throwable_xform.origin + (Vector3.UP * 2.5)), "State: " + str(throwable_info.state), 48)
		DebugDraw3D.draw_text((throwable_xform.origin + (Vector3.RIGHT * 2)), "Thrower: " + str(throwable_info.thrower_id), 48)

		var is_throw_button_pressed : bool = Input.is_action_pressed(controller.throw_action)
		var thrower_is_current_player : bool = throwable_info.thrower_id == player 
		var throwable_is_held : bool = throwable_info.state == Components.ThrowableState.Dragging

		if (!is_throw_button_pressed and throwable_is_held and thrower_is_current_player):
			self._throw_object(throwable_info, player_xform, throwable_xform, controller, thrower_info)

		if (distance_sqr > THROWABLE_DETECTION_RADIUS_SQR):
			return

		if(is_throw_button_pressed and throwable_info.state == Components.ThrowableState.Released):
			# Transition to dragging
			throwable_info.state = Components.ThrowableState.Dragging
			throwable_info.thrower_id = player
	)
	

func handle_throwables_physics(throwable: RID, throwable_comps: Array):
	var throwable_info : Components.Throwable = throwable_comps[0]
	var throwable_body : Components.PhysicsBody = throwable_comps[1]
	# var throwable_xform := throwable_body.get_transform()
	
	# Get the thrower's info
	if (!throwable_info.thrower_id.is_valid()):
		return
	var thrower_info : Components.Thrower = FlecsScene.get_component_from_entity(throwable_info.thrower_id, Components.Thrower.get_type_name())
	match throwable_info.state:
		Components.ThrowableState.Dragging:
			self.drag_object(throwable, throwable_info, throwable_body)
		Components.ThrowableState.Thrown:
			# Detach the joint
			self.release_object.call_deferred(throwable)
			var force := thrower_info.throwing_direction * thrower_info.throw_force
			throwable_body.set_gravity_scale(1)
			throwable_body.apply_impulse(force)

			# Restore the movement factor
			var thrower_mov : Components.Movement = FlecsScene.get_component_from_entity(throwable_info.thrower_id, Components.Movement.get_type_name())
			thrower_mov.speed_mod_factor = 1
			throwable_info.state = Components.ThrowableState.Released
		Components.ThrowableState.Released:
			throwable_info.thrower_id = rid_from_int64(0)
			pass

	pass

func release_object(thrower_id: RID) -> void:
	FlecsScene.entity_remove_component(thrower_id, Components.RopeJoint.get_type_name())


func drag_object(throwable_id: RID, throwable_info: Components.Throwable, throwable_body: Components.PhysicsBody):
	# Add the joint component to the throwable (bc a single thrower can carry many throwables, so the joint is attached to the throwable)
	var joint_comp : Components.RopeJoint = FlecsScene.get_component_from_entity(throwable_id, Components.RopeJoint.get_type_name())
	if joint_comp != null:
		return
	var thrower_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(throwable_info.thrower_id, Components.PhysicsBody.get_type_name())
	throwable_body.set_gravity_scale(0)

	var add_rope_comp := func _add_rope(p_joint):
		FlecsScene.entity_add_component_instance(throwable_id, Components.RopeJoint.get_type_name(), p_joint)

	var joint := Components.RopeJoint.new(thrower_body, throwable_body)
	joint.set_length(self.object_drag_length)
	joint.set_strength(self.object_drag_strength)

	add_rope_comp.call_deferred(joint)

	


func apply_rotation_sync(rope_joint: Components.RopeJoint, carrier_xform: Transform3D, carried_xform: Transform3D):
	var to_object : Vector3 = carried_xform.origin - carrier_xform.origin
	to_object.y = 0

	const epsilon := 0.001

	if to_object.length_squared() < epsilon:
		return

	to_object = to_object.normalized()

	# Get carrier's forward direction (where they're facing)
	var carrier_forward = -carrier_xform.basis.z
	carrier_forward.y = 0
	carrier_forward = carrier_forward.normalized()

	# Calculate the angle the object SHOULD be at relative to carrier
	var desired_angle = atan2(to_object.x, to_object.z)

	# Get the object's current rotation
	var carried_forward = -carried_xform.basis.z
	var current_angle = atan2(carried_forward.x, carried_forward.z)

	# The angle difference to correct
	var angle_diff = desired_angle - current_angle

	while angle_diff > PI:
		angle_diff -= TAU
	while angle_diff < -PI:
		angle_diff += TAU

	var rotation_strength = 50.0
	var torque = Vector3(0, angle_diff * rotation_strength, 0)
	rope_joint.body_b.apply_torque(torque)

	# Angular damping
	var angular_velocity_b = rope_joint.body_b.get_angular_velocity()
	var angular_damping = 5.0
	var damping_torque = -angular_velocity_b * angular_damping
	rope_joint.body_b.apply_torque(damping_torque)

func _physics_process(_delta: float):
	self.throwables_query.each(handle_throwables_physics)
	self.players_query.each(func _iter_players(player_entity: RID, components: Array):
		var controller : Components.Controller = components[1]
		var player_body : Components.PhysicsBody = components[2]

		var player_xform : Transform3D = player_body.get_transform()


		# var axis_direction : Vector2 = controller.get_axis_left().normalized()

		self.bags_query.each(func _iter_bags(_bag_entity: RID, bag_components: Array):
			var bag_info : Components.Bag = bag_components[0]
			var bag_body : Components.PhysicsBody = bag_components[1]
			var bag_xform : Transform3D = bag_body.get_transform()

			var distance_to_bag_sqr : float = player_xform.origin.distance_squared_to(bag_xform.origin) 


			const threshold := 16
			if distance_to_bag_sqr > threshold:
				return

			# This is laid out like this for debug purposes, move the if statement up so this does not evaluate all the time
			DebugDraw3D.draw_text(player_xform.origin + (Vector3.RIGHT * 2), "Able to hit!", 56)
			DebugDraw3D.draw_text(bag_xform.origin + (Vector3.LEFT * 3), "Last player hit: " + str(bag_info.last_player_id), 56)
			if !Input.is_action_pressed(controller.hit_key) || bag_info.last_player_id == player_entity:
				return
			bag_body.apply_impulse(Vector3.UP * 5)
			bag_info.last_player_id = player_entity
		)
	)
	pass
