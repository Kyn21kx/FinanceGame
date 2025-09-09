class_name Components

const movement_state_names = ["Idle", "Airbone", "Jumped", "Dashing"]

enum MovState { Idle, Airbone, Jumped, Dashing }

enum Item { Coin, Ingot }


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
	
	func get_axis_left() -> Vector2:
		var result := Vector2.ZERO

		if (Input.is_key_pressed(self.forward_key)):
			result += Vector2.UP
		if (Input.is_key_pressed(self.backward_key)):
			result += Vector2.DOWN
		if (Input.is_key_pressed(self.left_key)):
			result -= Vector2.RIGHT
		if (Input.is_key_pressed(self.right_key)):
			result += Vector2.RIGHT

		return result

	static func get_type_name() -> StringName:
		return "Controller"


class Inventory:
	var __storage : Dictionary
	
	var coins : float = 0: 
		get : return get_amount(Item.Coin)
		set(value) : set_amount(Item.Coin, value)
	 
	var ingots : float = 0:
		get : return get_amount(Item.Ingot)
		set(value) : set_amount(Item.Ingot, value) 
	
	func get_amount(item : Item) -> float:
		if (__storage.has(item)):
			return __storage[item]
			
		return 0
	
	func set_amount(item : Item, amount : float) -> void:
		__storage[item] = amount
	
	func add(item : Item, amount : float = 1):
		set_amount(item, get_amount(item) + amount)
	
	func remove(item : Item, amount : float):
		set_amount(item, max(0, get_amount(item) - amount))
	
	static func get_type_name() -> StringName:
		return "Inventory"


class Collectable:
	var item : Item
	var amount : float
	var weight: float
	
	static func get_type_name() -> StringName:
		return "Collectable"


class Collector:
	var attraction_range : float
	var attraction_factor : float
	var pickup_range : float
	
	static func get_type_name() -> StringName:
		return "Collector"


class Player:

	static func get_type_name() -> StringName:
		return "Player"


class Bag:
	var last_player_id: RID
	static func get_type_name() -> StringName:
		return "Bag"
