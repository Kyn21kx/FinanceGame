extends Node
class_name BagSystem # TODO: Rename to something like object interaction system

const THROWABLE_DETECTION_RADIUS_SQR := 5 * 5

var players_query := Query.new()
var bags_query := Query.new()
var throwables_query := Query.new()

func _ready() -> void:
	self.players_query.with_and_register(Components.Player.get_type_name())
	self.players_query.with_and_register(Components.Controller.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.bags_query.with_and_register(Components.Bag.get_type_name())
	self.bags_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.throwables_query.with_and_register(Components.Throwable.get_type_name())
	self.throwables_query.with_and_register(Components.PhysicsBody.get_type_name())
	
func _process(delta: float):
	self.players_query.each(_throwing_system_input)
	pass

func _throwing_system_input(_player: RID, components: Array):
	var controller : Components.Controller = components[1]
	var player_body : Components.PhysicsBody = components[2]
	var player_xform = player_body.get_transform()
	self.throwables_query.each(func _iter_throwables(throwable: RID, throwable_comps: Array):
		# Do a distance check and if it is close enough trigger the 
		var throwable_info : Components.Throwable = throwable_comps[0]
		var throwable_body : Components.PhysicsBody = throwable_comps[1]
		var throwable_xform := throwable_body.get_transform()
	
		var distance_sqr := throwable_xform.origin.distance_squared_to(player_xform.origin)
		DebugDraw3D.draw_text((throwable_xform.origin + (Vector3.UP * 2)), "State: " + str(throwable_info.state), 48)
		DebugDraw3D.draw_text((throwable_xform.origin + (Vector3.RIGHT * 2)), "Thrower: " + str(throwable_info.thrower_id), 48)
		if (distance_sqr > THROWABLE_DETECTION_RADIUS_SQR):
			return

		if (!Input.is_action_pressed(controller.throw_action)):
			if (throwable_info.thrower_id != _player): return
			var thrower_info : Components.Thrower = FlecsScene.get_component_from_entity(_player, Components.Thrower.get_type_name())
			if (throwable_info.state == Components.ThrowableState.Dragging):
				# Get the movement axis and apply that as the throwing direction if we want to throw
				var direction = controller.get_axis_left()
				thrower_info.throwing_direction = Vector3(direction.x, 0, direction.y) # Z and X
			
				throwable_info.state = Components.ThrowableState.Thrown
				return

		elif(throwable_info.state == Components.ThrowableState.Released):
			# Transition to dragging
			throwable_info.state = Components.ThrowableState.Dragging
			throwable_info.thrower_id = _player
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
			# Modify the speed based on the weight, and also move the physics body towards us
			var thrower_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(throwable_info.thrower_id, Components.PhysicsBody.get_type_name())
			var thrower_xform : Transform3D = thrower_body.get_transform()
			var throwable_xform = throwable_body.get_transform()
			throwable_xform.origin = thrower_xform.origin + ((Vector3.UP - thrower_xform.basis.z) * 2)
			throwable_body.set_gravity_scale(0)
			throwable_body.set_transform(throwable_xform)
		Components.ThrowableState.Thrown:
			var force := thrower_info.throwing_direction * thrower_info.throw_force
			throwable_body.set_gravity_scale(1)
			throwable_body.apply_impulse(force)
			throwable_info.state = Components.ThrowableState.Released
		Components.ThrowableState.Released:
			throwable_body.set_gravity_scale(1)

		

	pass

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
			if !Input.is_key_pressed(controller.hit_key) || bag_info.last_player_id == player_entity:
				return
			bag_body.apply_impulse(Vector3.UP * 5)
			bag_info.last_player_id = player_entity
		)
	)
	pass
