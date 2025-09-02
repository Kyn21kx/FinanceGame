class_name Components

enum MovState { Idle, Airbone, Dashing }

class PhysicsBody:
	var body_id: RID
	var shape: RID

	func _init(p_shape: Shape3D, p_world: World3D) -> void:
		self.shape = p_shape.get_rid()
		self.body_id = PhysicsServer3D.body_create()
		PhysicsServer3D.body_set_space(self.body_id, p_world.space)
		PhysicsServer3D.body_add_shape(self.body_id, self.shape)
		PhysicsServer3D.body_set_shape_transform(self.body_id, 0, Transform3D.IDENTITY)

		self.set_transform(Transform3D.IDENTITY)
	
	
	func get_transform() -> Transform3D:
		return PhysicsServer3D.body_get_state(self.body_id, PhysicsServer3D.BODY_STATE_TRANSFORM) as Transform3D

	func set_transform(xform: Transform3D) -> void:
		PhysicsServer3D.body_set_state(self.body_id, PhysicsServer3D.BODY_STATE_TRANSFORM, xform)

	func get_velocity() -> Vector3:
		return PhysicsServer3D.body_get_state(self.body_id, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
	
	func set_gravity_scale(scale: float) -> void:
		PhysicsServer3D.body_set_param(self.body_id, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE, scale) 
		pass
	
	# func set_velocity(velocity: Vector3) -> void:
		# pass

	func apply_force(force: Vector3) -> void:
		PhysicsServer3D.body_apply_central_force(self.body_id, force)

	func apply_impulse(impulse: Vector3) -> void:
		PhysicsServer3D.body_apply_central_impulse(self.body_id, impulse)

	func lock_axis(axis: int) -> void:
		PhysicsServer3D.body_set_axis_lock(self.body_id, axis, true)
	
	static func get_type_name() -> StringName:
		return "PhysicsBody"


class MeshComponent:
	var instance: RID
	var scenario: RID

	func _init(base: Mesh, p_world: World3D) -> void:
		self.instance = RenderingServer.instance_create()
		self.scenario = p_world.scenario
		RenderingServer.instance_set_base(self.instance, base.get_rid())
		RenderingServer.instance_set_scenario(self.instance, self.scenario)

	static func get_type_name() -> StringName:
		return "MeshComponent"


class Movement:
	var direction: Vector3
	var speed: float
	var jump_force: float

	var state: MovState = MovState.Idle
	
	static func get_type_name() -> StringName:
		return "Movement"


class Controller:
	# TODO: Maybe these could be functions or actions to make sure it works for controllers

	var forward_key: int
	var backward_key: int
	var right_key: int
	var left_key: int

	var jump_key: int
	
	static func get_type_name() -> StringName:
		return "Controller"
