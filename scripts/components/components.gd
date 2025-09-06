class_name Components

enum MovState { Idle, Airbone, Jumped, Dashing }
enum CollectableType { Coin }

class PhysicsBody:
	var body_id: RID
	var shape: RID

	func _init(p_shape: Shape3D, p_world: World3D, transform: Transform3D = Transform3D.IDENTITY) -> void:
		self.shape = p_shape.get_rid()
		self.body_id = PhysicsServer3D.body_create()
		PhysicsServer3D.body_set_space(self.body_id, p_world.space)
		PhysicsServer3D.body_add_shape(self.body_id, self.shape)
		PhysicsServer3D.body_set_shape_transform(self.body_id, 0, Transform3D.IDENTITY)
		PhysicsServer3D.body_set_mode(self.body_id, PhysicsServer3D.BODY_MODE_RIGID)

		self.set_transform(transform)
	
	
	func get_transform() -> Transform3D:
		return PhysicsServer3D.body_get_state(self.body_id, PhysicsServer3D.BODY_STATE_TRANSFORM) as Transform3D

	func set_transform(xform: Transform3D) -> void:
		PhysicsServer3D.body_set_state(self.body_id, PhysicsServer3D.BODY_STATE_TRANSFORM, xform)

	func set_velocity(velocity: Vector3) -> void:
		PhysicsServer3D.body_set_state(self.body_id, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, velocity)
	
	func get_velocity() -> Vector3:
		return PhysicsServer3D.body_get_state(self.body_id, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)
	
	func set_gravity_scale(scale: float) -> void:
		PhysicsServer3D.body_set_param(self.body_id, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE, scale) 
		pass
	
	func apply_force(force: Vector3) -> void:
		PhysicsServer3D.body_apply_central_force(self.body_id, force)

	func apply_impulse(impulse: Vector3) -> void:
		PhysicsServer3D.body_apply_central_impulse(self.body_id, impulse)

	func lock_axis(axis: int) -> void:
		PhysicsServer3D.body_set_axis_lock(self.body_id, axis, true)
	
	func set_collision_layer(layer: int) -> void:
		return PhysicsServer3D.body_set_collision_layer(self.body_id, layer)
	
	func set_collision_mask(mask: int) -> void:
		return PhysicsServer3D.body_set_collision_mask(self.body_id, mask)

	func set_bounciness(bounciness: float) -> void:
		PhysicsServer3D.body_set_param(self.body_id, PhysicsServer3D.BODY_PARAM_BOUNCE, bounciness)
	
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


class Dash:
	const DASH_COOLDOWN: float = 1

	var max_distance: float
	var speed: float
	var direction: Vector3

	# Will increment this every frame we are dashing for
	var curr_dashing_time: float

	var cooldown_time: float

	# Returns the time to check for against curr_time, such that when curr_time >= end_time the dash needs to be stopped 
	func get_end_time() -> float:
		# t = d / V
		return self.max_distance / self.speed
	
	static func get_type_name() -> StringName:
		return "Dash"


class Controller:
	# TODO: Maybe these could be functions or actions to make sure it works for controllers

	var forward_key: int
	var backward_key: int
	var right_key: int
	var left_key: int

	var jump_key: int

	var dash_key: int
	var hit_key: int
	
	static func get_type_name() -> StringName:
		return "Controller"


class Collectable:
	var weight: float
	var type: CollectableType = CollectableType.Coin 
	
	static func get_type_name() -> StringName:
		return "Collectable"


class Collector:
	var inventory : Dictionary
	var attraction_range : float
	var attraction_factor : float
	var pickup_range : float

	func get_in_inventory(collectable: CollectableType) -> float:
		if self.inventory.has(collectable):
			return self.inventory[collectable]
		
		return 0
	
	func add_to_inventory(collectable_type: CollectableType, amount : float = 1) -> void:
		self.inventory[collectable_type] = self.get_in_inventory(collectable_type) + amount
	
	func add_collectable_to_inventory(collectable: Collectable) -> void:
		self.add_to_inventory(collectable.type, 1)
	
	static func get_type_name() -> StringName:
		return "Collector"

class Player:

	static func get_type_name() -> StringName:
		return "Player"


class Bag:
	
	static func get_type_name() -> StringName:
		return "Bag"
