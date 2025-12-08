class_name Components

const movement_state_names = ["Empty", "Idle", "Airbone", "Jumped", "Dashing", "Falling", "Launched"]

# Note: Empty is NOT Idle, it's a state where there is nothing to determine the actor's movement
# It's more like "Waiting" for the next physics frame so its actual state gets calculated, but
# it's useful to distinguish it from the idle movement state where we could be grounded
enum MovState { Empty, Idle, Airbone, Jumped, Dashing, Falling, Launched } # Launched could be applied to items, we'll review that, it's up to the designers

enum Item {
	Coin = 1,
	Ingot = 3,
	Monster = 2,
	Tobacco = 2 << 1,
	Dumbell = 2 << 2,
	Coke = 2 << 3,
	Vitamin = 2 << 4,
	Fungi = 2 << 5,
	IsPowerUp = Monster | Tobacco | Dumbell | Coke | Vitamin | Fungi,
	PaintCan = 4
}
 
enum ThrowableState { Released, Dragging, Thrown }
enum PhysicsMasks {
	GizmoLayer = 1 << 31,
	JumpingLayer = 2 << 0,
}

enum JointType {
	Pin,
	Hinge,
	Slider,
	ConeTwist,
	Generic6DOF
}

enum Interaction { None, Use }

const THROWABLE_MAX_WEIGHT := 20

class PhysicsBody:
	var body_id: RID
	var shape: RID
	# We need to keep a ref to the shape
	var shape_ref: Shape3D
	var transform: Transform3D = Transform3D.IDENTITY

	var axis_lock_linear_x : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_LINEAR_X)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_LINEAR_X, value)

	var axis_lock_linear_y : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_LINEAR_Y)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_LINEAR_Y, value)

	var axis_lock_linear_z : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_LINEAR_Z)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_LINEAR_Z, value)

	var axis_lock_angular_x : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_ANGULAR_X)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X, value)

	var axis_lock_angular_y : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_ANGULAR_Y)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_Y, value)

	var axis_lock_angular_z : bool:
		get:
			return self.is_axis_locked(PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
		set(value):
			self.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_Z, value)


	func _init(p_shape: Shape3D = self.shape_ref, transform: Transform3D = Transform3D.IDENTITY) -> void:
		self.shape = p_shape.get_rid()
		self.shape_ref = p_shape
		self.body_id = PhysicsServer3D.body_create()
		# Bad fix, but will suffice for now
		var p_world : World3D = EditorImporterSystem.instance.get_world3d_consistent()
		PhysicsServer3D.body_set_space(self.body_id, p_world.space)
		PhysicsServer3D.body_add_shape(self.body_id, self.shape)
		PhysicsServer3D.body_set_shape_transform(self.body_id, 0, Transform3D.IDENTITY)
		PhysicsServer3D.body_set_mode(self.body_id, PhysicsServer3D.BODY_MODE_RIGID)

		self.set_transform(transform)
	
	func get_transform() -> Transform3D:
		return self.transform

	func set_transform(xform: Transform3D) -> void:
		PhysicsServer3D.body_set_state(self.body_id, PhysicsServer3D.BODY_STATE_TRANSFORM, xform)

	func set_velocity(velocity: Vector3) -> void:
		PhysicsServer3D.body_set_state(self.body_id, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY, velocity)
	
	func get_velocity() -> Vector3:
		return PhysicsServer3D.body_get_state(self.body_id, PhysicsServer3D.BODY_STATE_LINEAR_VELOCITY)

	func get_mass() -> float:
		return PhysicsServer3D.body_get_param(self.body_id, PhysicsServer3D.BODY_PARAM_MASS)
	
	func set_gravity_scale(scale: float) -> void:
		PhysicsServer3D.body_set_param(self.body_id, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE, scale) 
		pass

	func get_gravity_scale() -> float:
		return PhysicsServer3D.body_get_param(self.body_id, PhysicsServer3D.BODY_PARAM_GRAVITY_SCALE) 
	
	func apply_force(force: Vector3) -> void:
		PhysicsServer3D.body_apply_central_force(self.body_id, force)

	func apply_impulse(impulse: Vector3) -> void:
		PhysicsServer3D.body_apply_central_impulse(self.body_id, impulse)

	func lock_axis(axis: int, locked: bool = true) -> void:
		PhysicsServer3D.body_set_axis_lock(self.body_id, axis, locked)


	func is_axis_locked(axis: int) -> bool:
		return PhysicsServer3D.body_is_axis_locked(self.body_id, axis)
	
	func set_collision_layer(layer: int) -> void:
		return PhysicsServer3D.body_set_collision_layer(self.body_id, layer)
	
	func set_collision_mask(mask: int) -> void:
		return PhysicsServer3D.body_set_collision_mask(self.body_id, mask)

	func set_bounciness(bounciness: float) -> void:
		PhysicsServer3D.body_set_param(self.body_id, PhysicsServer3D.BODY_PARAM_BOUNCE, bounciness)
	
	func set_body_type(type: int) -> void:
		PhysicsServer3D.body_set_mode(self.body_id, type)

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "PhysicsBody"


class PhysicsJoint:

	var joint_id : RID
	var joint_type: JointType

	func _init(body_a: RID, body_b: RID, type: JointType, local_a: Vector3 = Vector3.ZERO, local_b: Vector3 = Vector3.ZERO) -> void:
		self.joint_id = PhysicsServer3D.joint_create()
		self.joint_type = type

		match self.joint_type:
			JointType.Pin:
				PhysicsServer3D.joint_make_pin(self.joint_id, body_a, local_a, body_b, local_b)
			JointType.Hinge:
				PhysicsServer3D.joint_make_hinge(self.joint_id, body_a, Transform3D.IDENTITY, body_b, Transform3D.IDENTITY)
			JointType.Slider:
				PhysicsServer3D.joint_make_slider(self.joint_id, body_a, Transform3D.IDENTITY, body_b, Transform3D.IDENTITY)
			JointType.ConeTwist:
				PhysicsServer3D.joint_make_cone_twist(self.joint_id, body_a, Transform3D.IDENTITY, body_b, Transform3D.IDENTITY)
			JointType.Generic6DOF:
				PhysicsServer3D.joint_make_generic_6dof(self.joint_id, body_a, Transform3D.IDENTITY, body_b, Transform3D.IDENTITY)



	func set_collision_between_connected_bodies(enabled: bool) -> void:
		PhysicsServer3D.joint_disable_collisions_between_bodies(self.joint_id, !enabled)

	func set_pin_bias(bias: float) -> void:
		PhysicsServer3D.pin_joint_set_param(self.joint_id, PhysicsServer3D.PIN_JOINT_BIAS, bias) 

	func set_pin_damping(damping: float) -> void:
		PhysicsServer3D.pin_joint_set_param(self.joint_id, PhysicsServer3D.PIN_JOINT_DAMPING, damping)

	func dispose() -> void:
		PhysicsServer3D.free_rid(self.joint_id)
		self.joint_id = RID()

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "PhysicsJoint"

class RopeJoint:
	var body_a: PhysicsBody
	var body_b: PhysicsBody
	var length: float = 0.1
	var strength: float = 1.0
	var damping: float = 0.5

	func _init(p_body_a: PhysicsBody, p_body_b: PhysicsBody) -> void:
		self.body_a = p_body_a
		self.body_b = p_body_b
		pass

	func set_length(p_length: float) -> void:
		self.length = p_length
	
	func set_strength(p_strength: float) -> void:
		self.strength = p_strength
	
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "RopeJoint"

class MeshComponent:
	var instance: RID
	var scenario: RID
	# We NEED to store this bc meshes are RefCounted
	var mesh: Mesh

	func _init(base: Mesh, p_world: World3D) -> void:
		self.instance = RenderingServer.instance_create()
		self.mesh = base
		self.scenario = p_world.scenario
		RenderingServer.instance_set_base(self.instance, base.get_rid())
		RenderingServer.instance_set_scenario(self.instance, self.scenario)

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "MeshComponent"

class Movement:
	const JUMP_BUFFER_TIME_MSEC = 50
	var direction: Vector3
	var speed: float
	var speed_mod_factor: float = 1
	var jump_force: float
	var last_jump_input_time: float = INF
	var bounce_force: float = 1

	var state: MovState = MovState.Idle
	
	static func get_readonly_props() -> Dictionary:
		return { "direction": true, "speed_mod_factor": true, "state": true}
	
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
	
	static func get_readonly_props() -> Dictionary:
		return { "direction": true, "curr_dashing_time": true, "curr_cooldown_time": true }
	
	static func get_type_name() -> StringName:
		return "Dash"


class Controller:
	# TODO: Maybe these could be functions or actions to make sure it works for controllers
	var forward_key: StringName
	var backward_key: StringName
	var right_key: StringName
	var left_key: StringName

	var rs_up: StringName
	var rs_down: StringName
	var rs_left: StringName
	var rs_right: StringName

	var horizontal_axis: StringName
	var vertical_axis: StringName

	var jump_key: StringName

	var dash_key: StringName
	var hit_key: StringName
	var throw_action: StringName
	var use_action: StringName
	
	func get_axis_left() -> Vector2:
		var horizontal: float = Input.get_axis(self.left_key, self.right_key)
		var vertical: float = Input.get_axis(self.backward_key, self.forward_key)
		return Vector2(horizontal, -vertical)

	func get_axis_right() -> Vector2:
		var horizontal: float = Input.get_axis(self.rs_left, self.rs_right)
		var vertical: float = Input.get_axis(self.rs_down, self.rs_up)
		return Vector2(horizontal, -vertical)

	static func get_readonly_props() -> Dictionary:
		return {}
	
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
	
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Inventory"


class Collectable:
	var item : Item
	var amount : float
	var weight: float
	
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Collectable"


class Collector:
	var attraction_range : float
	var attraction_factor : float
	var pickup_range : float
	
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Collector"


class Player:

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Player"


class Bag:
	var last_player_id: RID
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Bag"


class Throwable:
	var weight: float
	var state: ThrowableState = ThrowableState.Released
	var thrower_id: RID = rid_from_int64(0)

	func _init(p_weight: float = 0) -> void:
		self.weight = p_weight
		pass

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "Throwable"

class Thrower:
	var throw_force: float
	var throwing_direction: Vector3

	static func get_readonly_props() -> Dictionary:
		return {"throwing_direction": true}
	
	static func get_type_name() -> StringName:
		return "Thrower"

class MagneticAttracter:
	var strength: float
	var threshold: float

	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "MagneticAttracter"
	

class MagneticTarget:
	static func get_readonly_props() -> Dictionary:
		return {}
	
	static func get_type_name() -> StringName:
		return "MagneticTarget"

class HeartResistance:
	const INITIAL_BPM : float = 80
	const CRITICAL_BPM_HIGH : float = 190
	const CRITICAL_BPM_LOW : float = 45
	const LETHAL_BPM_HIGH : float = 220
	const LETHAL_BPM_LOW : float = 30

	var bpm: float = INITIAL_BPM

class CameraTarget:
	static func get_type_name() -> StringName:
		return "CameraTarget"

class Interactable:
	var interaction_range : float
	var cooldown : int # miliseconds
	var last_interaction : int = -1 # miliseconds
	var enabled : bool = true
	
	func _init(interaction_range : float = 10, cooldown : int = 10) -> void:
		self.interaction_range = interaction_range
		self.cooldown = cooldown
	
	static func get_type_name() -> StringName:
		return "Interactable"

class Interactor:
	static func get_type_name() -> StringName:
		return "Interactor"

class InteractionEvent:
	var interactor : RID
	var interactable : RID 
	var interaction : Interaction
	
	static func get_type_name() -> StringName:
		return "InteractionEvent"

class DispenserComponent:
	static func get_type_name() -> StringName:
		return "DispenserComponent"
