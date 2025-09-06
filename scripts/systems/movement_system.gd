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
	# TODO: Check airbone dashing

	if (movement.state == Components.MovState.Jumped):
		body.apply_impulse(Vector3.UP * movement.jump_force)
		

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

	if (movement.state == Components.MovState.Airbone):
		# Increase the gravity of our body
		body.set_gravity_scale(5)
	else:
		body.set_gravity_scale(1)


	# TODO: Move to independent function when needed
	body.apply_force(movement.direction * movement.speed)
	pass

func _handle_dash(delta: float,  movement: Components.Movement, body: Components.PhysicsBody, dash_info: Components.Dash):
	# Get the elapsed time
	var curr_vel : Vector3 = body.get_velocity()
	if (dash_info.curr_dashing_time >= dash_info.get_end_time()):
		# If the dash feels too "slippery" uncomment these
		curr_vel.x = 0
		curr_vel.z = 0
		body.set_velocity(curr_vel)

		# Reset dash info
		dash_info.curr_dashing_time = 0
		movement.state = Components.MovState.Idle
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
	var input := Vector3.ZERO
	if (Input.is_key_pressed(controller.forward_key)):
		input -= xform.basis.z
	if (Input.is_key_pressed(controller.backward_key)):
		input += xform.basis.z
	if (Input.is_key_pressed(controller.left_key)):
		input -= xform.basis.x
	if (Input.is_key_pressed(controller.right_key)):
		input += xform.basis.x

	if (Input.is_key_pressed(controller.jump_key) && movement.state != Components.MovState.Airbone):
		movement.state = Components.MovState.Jumped

	input = input.normalized()

	if (input != Vector3.ZERO && movement.state != Components.MovState.Dashing):
		dash.direction = input
		# Check if our direction is close enough to the bag and magnetize the dash towards it
		self.bag_query.each(func iter_bag(_bag_entity: RID, bag_components: Array):
			var bag_body : Components.PhysicsBody = bag_components[1]
			var direction_to_bag : Vector3 = (bag_body.get_transform().origin - xform.origin).normalized()
			var inputDotBag : float = input.dot(direction_to_bag)
			print(inputDotBag)
			# if it's close to 1, magnetize
			const threshold : float = 0.94
			if inputDotBag >= threshold:
				dash.direction = direction_to_bag
		)


	if (Input.is_key_pressed(controller.dash_key) && movement.state != Components.MovState.Dashing && dash.cooldown_time <= 0):
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
	)
	pass
