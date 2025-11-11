extends Node
class_name EntitySpawnSystem

# Maybe the player prefab here
@export
var player_model: Mesh

@export
var player_prefab: PackedScene

@export
var player_shape: Shape3D

@export
var player_layer: int

@export
var coin_model: Mesh

@export
var coin_shape: Shape3D

@export
var sample_pos: Vector3

var box_mesh := BoxMesh.new()

var box_shape := BoxShape3D.new()

var ball_mesh := SphereMesh.new()

var ball_shape := SphereShape3D.new()

func _ready() -> void:
	var float_comp : float = 4.8
	var test := FlecsScene.create_raw_entity_with_name("TestEntity")
	FlecsScene.entity_add_component_instance(test, "Arbitrary", float_comp)
	
	# Spawn the player at start with its default components
	var controller_comp_p1 := Components.Controller.new()
	controller_comp_p1.forward_key = KEY_W
	controller_comp_p1.backward_key = KEY_S
	controller_comp_p1.left_key = KEY_A
	controller_comp_p1.right_key = KEY_D
	controller_comp_p1.jump_key = KEY_SPACE
	controller_comp_p1.dash_key = KEY_SHIFT
	controller_comp_p1.hit_key = KEY_F
	controller_comp_p1.throw_action = "throw_p1"
	self._make_player(controller_comp_p1)

	# Second player for testing
	var controller_comp_p2 := Components.Controller.new()
	controller_comp_p2.forward_key = KEY_UP
	controller_comp_p2.backward_key = KEY_DOWN
	controller_comp_p2.left_key = KEY_LEFT
	controller_comp_p2.right_key = KEY_RIGHT
	controller_comp_p2.jump_key = KEY_ALT
	controller_comp_p2.dash_key = KEY_CTRL
	controller_comp_p2.hit_key = KEY_M
	controller_comp_p2.throw_action = "throw_p2"
	self._make_player(controller_comp_p2)
	
	self._make_coin(Vector3(2, 0, 1))
	self._make_coin(Vector3(3, 0, 1))
	self._make_coin(Vector3(4, 0, 1))
	self._make_coin(Vector3(1.5, 0, 1.5))
	self._make_coin(Vector3(3.5, 0, 1.5))
	self._make_coin(Vector3(-2, 0, -2))
	self._make_coin(Vector3(-2, 0, -2.5))
	self._make_coin(Vector3(-2.5, 0, -3))
	self._make_coin(Vector3(-1, 0, -3.5))
	
	self._make_camera()
	
	self._make_env_object(self.box_mesh, 10)
	
	self._make_ball()

func _make_ball() -> void:
	var ball : RID = FlecsScene.create_raw_entity_with_name("Ball")
	var mesh_comp := Components.MeshComponent.new(ball_mesh, self.get_viewport().world_3d)
	var xform := Transform3D(Basis(), Vector3(0, 5, -3))
	var body := Components.PhysicsBody.new(ball_shape, self.get_viewport().world_3d, xform)
	var attracter := Components.MagneticAttracter.new()
	attracter.strength = 30
	attracter.threshold = 30
	body.set_bounciness(0.7)
	body.set_gravity_scale(0.1)
	var bag_comp := Components.Bag.new()

	FlecsScene.entity_add_component_instance(ball, Components.PhysicsBody.get_type_name(), body)
	FlecsScene.entity_add_component_instance(ball, Components.MeshComponent.get_type_name(), mesh_comp)
	FlecsScene.entity_add_component_instance(ball, Components.Bag.get_type_name(), bag_comp)
	FlecsScene.entity_add_component_instance(ball, Components.MagneticAttracter.get_type_name(), attracter)
	
	var camera_target_comp := Components.CameraTarget.new(1)
	FlecsScene.entity_add_component_instance(ball, Components.CameraTarget.get_type_name(), camera_target_comp)

# TODO: Allow them to make them from a typed resource
func _make_env_object(mesh: Mesh, weight: float) -> void:
	var obj : RID = FlecsScene.create_raw_entity_with_name("Obstacle")
	var throwable := Components.Throwable.new(weight)
	FlecsScene.entity_add_component_instance(obj, Components.Throwable.get_type_name(), throwable)
	var body := Components.PhysicsBody.new(self.box_shape, self.get_viewport().world_3d)
	var mesh_comp := Components.MeshComponent.new(mesh, self.get_viewport().world_3d)
	FlecsScene.entity_add_component_instance(obj, Components.PhysicsBody.get_type_name(), body) 
	FlecsScene.entity_add_component_instance(obj, Components.MeshComponent.get_type_name(), mesh_comp) 
	var attracted_comp := Components.MagneticTarget.new()
	FlecsScene.entity_add_component_instance(obj, Components.MagneticTarget.get_type_name(), attracted_comp) 
	pass

func _make_player(controller_comp: Components.Controller) -> void:
	var player : RID = FlecsScene.create_raw_entity_with_name("Player")

	var player_comp := Components.Player.new()
	FlecsScene.entity_add_component_instance(player, Components.Player.get_type_name(), player_comp)

	var mesh_comp := Components.MeshComponent.new(self.player_model, self.get_viewport().world_3d)
	FlecsScene.entity_add_component_instance(player, Components.MeshComponent.get_type_name(), mesh_comp)
	
	var physics_comp := Components.PhysicsBody.new(self.player_shape, self.get_viewport().world_3d)
	physics_comp.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X | PhysicsServer3D.BODY_AXIS_ANGULAR_Y | PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
	FlecsScene.entity_add_component_instance(player, Components.PhysicsBody.get_type_name(), physics_comp)
	
	var movement_comp := Components.Movement.new()
	movement_comp.speed = 20 
	movement_comp.jump_force = 10
	FlecsScene.entity_add_component_instance(player, Components.Movement.get_type_name(), movement_comp)
	
	FlecsScene.entity_add_component_instance(player, Components.Controller.get_type_name(), controller_comp)

	var dash_comp := Components.Dash.new()
	dash_comp.max_distance = 10
	dash_comp.speed = 30
	FlecsScene.entity_add_component_instance(player, Components.Dash.get_type_name(), dash_comp)
	
	var collector_comp := Components.Collector.new()
	collector_comp.attraction_range = 2
	collector_comp.attraction_factor = 7
	collector_comp.pickup_range = 1
	FlecsScene.entity_add_component_instance(player, Components.Collector.get_type_name(), collector_comp)
	
	var inventory_comp := Components.Inventory.new()
	FlecsScene.entity_add_component_instance(player, Components.Inventory.get_type_name(), inventory_comp)
	
	var thrower_comp := Components.Thrower.new()
	thrower_comp.throw_force = 30
	FlecsScene.entity_add_component_instance(player, Components.Thrower.get_type_name(), thrower_comp)
	
	var camera_target := Components.CameraTarget.new(2)
	FlecsScene.entity_add_component_instance(player, Components.CameraTarget.get_type_name(), camera_target)

func _make_coin(position: Vector3) -> void:
	var coin : RID = FlecsScene.create_raw_entity()
	var mesh_comp := Components.MeshComponent.new(self.coin_model, self.get_viewport().world_3d)
	FlecsScene.entity_add_component_instance(coin, Components.MeshComponent.get_type_name(), mesh_comp)
	
	var physics_comp := Components.PhysicsBody.new(self.coin_shape, self.get_viewport().world_3d)
	physics_comp.set_collision_layer(0)
	physics_comp.set_collision_mask(2)
	var transform : Transform3D = physics_comp.get_transform()
	transform.origin = position # set entity position on the world
	transform.basis = Basis(Vector3.LEFT, deg_to_rad(90)) # rotate the coin so that it is upside
	physics_comp.set_transform(transform)
	physics_comp.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X | PhysicsServer3D.BODY_AXIS_ANGULAR_Y | PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
	FlecsScene.entity_add_component_instance(coin, Components.PhysicsBody.get_type_name(), physics_comp) 
	
	var collectable_comp := Components.Collectable.new()
	collectable_comp.item = Components.Item.Coin
	collectable_comp.amount = 1
	collectable_comp.weight = 2
	FlecsScene.entity_add_component_instance(coin, Components.Collectable.get_type_name(), collectable_comp)

func _make_camera() -> void:
	var camera_node : Camera3D = $"../Camera3D"
	var camera : RID = FlecsScene.create_raw_entity()
	var camera_comp := Components.Camera.new(camera_node)
	
	camera_comp.zoom_in_speed = 0.2
	camera_comp.zoom_out_seed = 2
	camera_comp.zoom_direction = camera_node.basis.z * -1
	camera_comp.max_zoom_in = 10
	camera_comp.max_zoom_out = 100
	camera_comp.target_padding = 4
	camera_comp.pivot = camera_node.position
	camera_comp.do_look_at_primary_objective = false
	
	FlecsScene.entity_add_component_instance(camera, Components.Camera.get_type_name(), camera_comp)

func _process(delta: float) -> void:
	pass
