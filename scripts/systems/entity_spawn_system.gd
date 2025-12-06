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

	controller_comp_p1.forward_key = "move_up_p1"
	controller_comp_p1.backward_key = "move_down_p1"
	controller_comp_p1.left_key = "move_left_p1"
	controller_comp_p1.right_key = "move_right_p1"
	controller_comp_p1.jump_key = "jump_p1"
	controller_comp_p1.dash_key = "dash_p1"
	controller_comp_p1.hit_key = "hit_p1"
	controller_comp_p1.throw_action = "throw_p1"
	controller_comp_p1.rs_up = "rs_up_p1"
	controller_comp_p1.rs_down = "rs_down_p1"
	controller_comp_p1.rs_left = "rs_left_p1"
	controller_comp_p1.rs_right = "rs_right_p1"
	self._make_player(controller_comp_p1)

	# Second player for testing
	var controller_comp_p2 := Components.Controller.new()
	controller_comp_p2.forward_key = "move_up_p2"
	controller_comp_p2.backward_key = "move_down_p2"
	controller_comp_p2.left_key = "move_left_p2"
	controller_comp_p2.right_key = "move_right_p2"
	controller_comp_p2.jump_key = "jump_p2"
	controller_comp_p2.dash_key = "dash_p2"
	controller_comp_p2.hit_key = "hit_p2"
	controller_comp_p2.throw_action = "throw_p2"
	controller_comp_p2.rs_up = "rs_up_p2"
	controller_comp_p2.rs_down = "rs_down_p2"
	controller_comp_p2.rs_left = "rs_left_p2"
	controller_comp_p2.rs_right = "rs_right_p2"
	self._make_player(controller_comp_p2)
	
	var coin_shape : Shape3D = self.coin_model.create_convex_shape()
	self._make_coin(Vector3(2, 0, 1), coin_shape)
	self._make_coin(Vector3(3, 0, 1), coin_shape)
	self._make_coin(Vector3(4, 0, 1), coin_shape)
	self._make_coin(Vector3(1.5, 0, 1.5), coin_shape)
	self._make_coin(Vector3(3.5, 0, 1.5), coin_shape)
	self._make_coin(Vector3(-2, 0, -2), coin_shape)
	self._make_coin(Vector3(-2, 0, -2.5), coin_shape)
	self._make_coin(Vector3(-2.5, 0, -3), coin_shape)
	self._make_coin(Vector3(-1, 0, -3.5), coin_shape)


	self._make_env_object(self.box_mesh, 10)
	
	self._make_ball()

func _make_ball() -> void:
	var ball : RID = FlecsScene.create_raw_entity_with_name("Ball")
	var mesh_comp := Components.MeshComponent.new(ball_mesh, self.get_viewport().world_3d)
	var xform := Transform3D(Basis(), Vector3(0, 5, -3))
	var body := Components.PhysicsBody.new(ball_shape, xform)
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
	FlecsScene.entity_add_component_instance(ball, Components.CameraTarget.get_type_name(), Components.CameraTarget.new())

# TODO: Allow them to make them from a typed resource
func _make_env_object(mesh: Mesh, weight: float) -> void:
	var obj : RID = FlecsScene.create_raw_entity_with_name("Obstacle")
	var throwable := Components.Throwable.new(weight)
	FlecsScene.entity_add_component_instance(obj, Components.Throwable.get_type_name(), throwable)
	var body := Components.PhysicsBody.new(self.box_shape)
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
	
	var physics_comp := Components.PhysicsBody.new(self.player_shape)
	physics_comp.set_body_type(PhysicsServer3D.BODY_MODE_RIGID_LINEAR)
	physics_comp.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X | PhysicsServer3D.BODY_AXIS_ANGULAR_Y | PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
	FlecsScene.entity_add_component_instance(player, Components.PhysicsBody.get_type_name(), physics_comp)
	
	var movement_comp := Components.Movement.new()
	movement_comp.speed = 20 
	movement_comp.jump_force = 20
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

	var throwable_comp := Components.Throwable.new(10)
	FlecsScene.entity_add_component_instance(player, Components.Throwable.get_type_name(), throwable_comp)

	FlecsScene.entity_add_component_instance(player, Components.CameraTarget.get_type_name(), Components.CameraTarget.new())


func _make_coin(position: Vector3, coin_shape: Shape3D) -> void:
	var coin : RID = FlecsScene.create_raw_entity()
	var mesh_comp := Components.MeshComponent.new(self.coin_model, self.get_viewport().world_3d)
	FlecsScene.entity_add_component_instance(coin, Components.MeshComponent.get_type_name(), mesh_comp)
	
	var physics_comp := Components.PhysicsBody.new(coin_shape)
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


func _process(delta: float) -> void:
	pass
