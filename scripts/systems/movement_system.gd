extends Node
class_name MovementSystem

var players_query := Query.new()

func _ready() -> void:
	self.players_query.with_and_register(Components.Movement.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.players_query.with_and_register(Components.Controller.get_type_name())
	self.players_query.with_and_register(Components.Dash.get_type_name())
	pass

func _handle_movement_state(movement: Components.Movement, body: Components.PhysicsBody):
	var space_state := self.get_viewport().world_3d.direct_space_state
	var origin : Vector3 = body.get_transform().origin
	var query := PhysicsRayQueryParameters3D.create(origin, origin - (Vector3.UP))
	var ray_result : Dictionary = space_state.intersect_ray(query)
	var vel_y_comp : float = absf(body.get_velocity().y)
	const threshold : float = 0.3
	if (ray_result.is_empty()):
		if (vel_y_comp > threshold):
			movement.state = Components.MovState.Airbone
	else:
		movement.state = Components.MovState.Idle

	# print(movement.state)
	if (movement.state == Components.MovState.Airbone):
		# Increase the gravity of our body
		body.set_gravity_scale(5)
	else:
		body.set_gravity_scale(1)

	pass

func _handle_dash(delta: float,  movement: Components.Movement, body: Components.PhysicsBody, dash_info: Components.Dash):
	# Get the elapsed time
	if (dash_info.curr_time >= dash_info.get_end_time()):
		movement.state = Components.MovState.Idle
		return
	movement.state = Components.MovState.Dashing

	dash_info.curr_time += delta
	var curr_vel : Vector3 = body.get_velocity()
	var dash_vel := dash_info.direction * dash_info.speed
	
	# Preserve gravity and jumping
	dash_vel.y = curr_vel.y
	body.set_velocity(dash_vel)

func _physics_process(delta: float) -> void:
	# TODO: Process this by controller component
	self.players_query.each(func _move_bodies(components: Array):
		var movement: Components.Movement = components[0]
		var body: Components.PhysicsBody = components[1]
		var controller: Components.Controller = components[2]
		var dash: Components.Dash = components[3]

		# Grounded will be if the velocity on the Y component is not close to 0
		var xform : Transform3D = body.get_transform()
		var input := Vector3.ZERO
		var impulse := Vector3.ZERO
		if (Input.is_key_pressed(controller.forward_key)):
			input -= xform.basis.z
		if (Input.is_key_pressed(controller.backward_key)):
			input += xform.basis.z
		if (Input.is_key_pressed(controller.left_key)):
			input -= xform.basis.x
		if (Input.is_key_pressed(controller.right_key)):
			input += xform.basis.x

		if (Input.is_key_pressed(controller.jump_key) && movement.state != Components.MovState.Airbone):
			impulse = Vector3.UP

		if (input != Vector3.ZERO && movement.state != Components.MovState.Dashing):
			dash.direction = input

		if (Input.is_key_pressed(controller.dash_key) && movement.state != Components.MovState.Dashing):
			_handle_dash(delta, movement, body, dash)

		_handle_movement_state(movement, body)

		movement.direction = input.normalized()
		body.apply_force(movement.direction * movement.speed)
		body.apply_impulse(impulse * movement.jump_force)
		pass
	)
	pass
