extends Node
class_name MovementSystem

var players_query := Query.new()

func _ready() -> void:
	self.players_query.with_and_register(Components.Movement.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.players_query.with_and_register(Components.Controller.get_type_name())
	pass

func _physics_process(_delta: float) -> void:
	# TODO: Process this by controller component
	self.players_query.each(func _move_bodies(components: Array):
		var movement: Components.Movement = components[0]
		var body: Components.PhysicsBody = components[1]
		var controller: Components.Controller = components[2]

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
		if (Input.is_key_pressed(controller.jump_key) && movement.state != Components.MovState.Jumping):
			impulse = Vector3.UP
			movement.state = Components.MovState.Jumping

		movement.direction = input.normalized()
		body.apply_force(movement.direction * movement.speed)
		body.apply_impulse(impulse * movement.jump_force)
		pass
	)
	pass
