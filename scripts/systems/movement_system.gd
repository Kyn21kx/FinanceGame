extends Node
class_name MovementSystem

var players_query := Query.new()
var input_comps_query := Query.new()
var bag_query := Query.new()

func _ready() -> void:
	# Will update the transforms based on the directions and state machine
	self.players_query.with_and_register(Components.Movement.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.players_query.with_and_register(Components.Dash.get_type_name())
	
	# Will set the directions of eveything
	self.input_comps_query.with_and_register(Components.Controller.get_type_name())
	self.input_comps_query.with_and_register(Components.Movement.get_type_name())
	self.input_comps_query.with_and_register(Components.Dash.get_type_name())
	self.input_comps_query.with_and_register(Components.PhysicsBody.get_type_name())

	self.bag_query.with_and_register(Components.Bag.get_type_name())
	self.bag_query.with_and_register(Components.PhysicsBody.get_type_name())



func _handle_movement_state(delta: float, movement: Components.Movement, body: Components.PhysicsBody, dash: Components.Dash):
	if (movement.state == Components.MovState.Dashing):
		dash.cooldown_time = dash.DASH_COOLDOWN
		_handle_dash(delta, movement, body, dash)
		return

	if (movement.state == Components.MovState.Jumped):
		body.apply_impulse(Vector3.UP * movement.jump_force)
		# Immediately apply airbone state
		movement.state = Components.MovState.Airbone
		

	var shape := BoxShape3D.new()
	shape.size = Vector3(1, 0.5, 1) # Just a small rectangle thingy
	var space_state := self.get_viewport().world_3d.direct_space_state
	var origin : Vector3 = body.get_transform().origin + Vector3.DOWN - (Vector3.RIGHT * (shape.size.x / 2) - (Vector3.FORWARD * (shape.size.z / 2)))
	var query_xform := Transform3D(Basis(), origin)
	var query := PhysicsShapeQueryParameters3D.new()
	query.transform = query_xform
	query.shape = shape
	query.exclude = [body.shape]
	var all_res : Array[Dictionary] = space_state.intersect_shape(query, 1)
	var shape_color : Color = Color.GREEN
	var raw_y_velocity : float = body.get_velocity().y
	var vel_y_comp : float = absf(raw_y_velocity)
	const threshold : float = 0.5

	if (all_res.is_empty() or all_res[0].is_empty() or all_res[0].collider_id == 0):
		if (vel_y_comp > threshold):
			movement.state = Components.MovState.Airbone
			shape_color = Color.RED
			body.set_gravity_scale(5)
		if (raw_y_velocity < 0):
			movement.state = Components.MovState.Falling

	elif vel_y_comp == 0 and movement.state != Components.MovState.Idle: # Additional cond to avoid repeating the gravity scale setter
		movement.state = Components.MovState.Idle
		body.set_gravity_scale(1)

	DebugDraw3D.draw_box(origin, Quaternion.IDENTITY, shape.size, shape_color)
	# TODO: Move to independent function when needed
	body.apply_force(movement.direction * movement.speed * movement.speed_mod_factor)
	pass

func _handle_dash(delta: float,  movement: Components.Movement, body: Components.PhysicsBody, dash_info: Components.Dash):
	# Get the elapsed time
	var curr_vel : Vector3 = body.get_velocity()
	if (dash_info.curr_dashing_time >= dash_info.get_end_time()):
		# If the dash feels too "slippery" uncomment these
		# curr_vel.x = 0
		# curr_vel.z = 0
		# body.set_velocity(curr_vel)

		# Reset dash info
		dash_info.curr_dashing_time = 0
		movement.state = Components.MovState.Empty
		return
	movement.state = Components.MovState.Dashing

	dash_info.curr_dashing_time += delta
	var dash_vel := dash_info.direction * dash_info.speed
	
	# Preserve gravity and jumping
	dash_vel.y = curr_vel.y
	body.set_velocity(dash_vel)


func _handle_input(_entity: RID, components: Array):
	var controller: Components.Controller = components[0]
	var movement: Components.Movement = components[1]
	var dash: Components.Dash = components[2]
	var body : Components.PhysicsBody = components[3]
	
	var xform : Transform3D = body.get_transform()
	var horizontal: float = Input.get_axis(controller.left_key, controller.right_key)
	var vertical: float = Input.get_axis(controller.backward_key, controller.forward_key)
	
	var input := Vector3.ZERO
	input += xform.basis.x * horizontal
	input += xform.basis.z * -vertical

	var curr_time := Time.get_ticks_msec()
	var buffer_time_diff := absf(curr_time - movement.last_jump_input_time)

	if (Input.is_action_pressed(controller.jump_key) or buffer_time_diff <= movement.JUMP_BUFFER_TIME_MSEC):
		if (movement.state == Components.MovState.Idle):
			movement.state = Components.MovState.Jumped
		# Buffer the input only if we're falling
		if (movement.state == Components.MovState.Falling):
			movement.last_jump_input_time = Time.get_ticks_msec()


	input = input.normalized()


	if (input != Vector3.ZERO && movement.state != Components.MovState.Dashing):
		dash.direction = input
		DebugDraw3D.draw_arrow(xform.origin, xform.origin + dash.direction * 2)
		# Check if our direction is close enough to the bag and magnetize the dash towards it
		self.bag_query.each(func iter_bag(_bag_entity: RID, bag_components: Array):
			var bag_body : Components.PhysicsBody = bag_components[1]
			var bag_position : Vector3 = bag_body.get_transform().origin

			# First check if we are within range
			var close_to_bag_distance_sqr : float = dash.max_distance * dash.max_distance
			var distance_to_bag_sqr : float = xform.origin.distance_squared_to(bag_position)
			if (distance_to_bag_sqr > close_to_bag_distance_sqr):
				return

			var direction_to_bag : Vector3 = (bag_position - xform.origin).normalized()
			var input_dot_bag : float = input.dot(direction_to_bag)
			DebugDraw3D.draw_arrow(bag_position, bag_position + direction_to_bag, Color.RED * input_dot_bag)

			# if it's close to 1, magnetize
			const threshold : float = 0.85
			if input_dot_bag >= threshold:
				dash.direction = direction_to_bag
		)


	if (Input.is_action_pressed(controller.dash_key) && movement.state != Components.MovState.Dashing && dash.cooldown_time <= 0):
		movement.state = Components.MovState.Dashing

	movement.direction = input

func _process(_delta: float) -> void:
	self.input_comps_query.each(_handle_input)

func _physics_process(delta: float) -> void:
	# TODO: Process this by controller component
	self.players_query.each(func _move_bodies(_entity: RID, components: Array):
		var movement: Components.Movement = components[0]
		var body: Components.PhysicsBody = components[1]
		var dash: Components.Dash = components[2]

		if (dash.cooldown_time > 0):
			dash.cooldown_time -= delta

		
		_handle_movement_state(delta, movement, body, dash)
		DebugDraw3D.draw_text(body.get_transform().origin + (Vector3.UP * 2), "State: " + Components.movement_state_names[movement.state], 56)
	)
	pass
