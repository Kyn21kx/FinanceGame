extends Node
class_name EntitySpawnSystem

# Maybe the player prefab here
@export
var player_model: Mesh

@export
var player_shape: Shape3D

@export
var player_layer: int

@export
var coin_model: Mesh

@export
var coin_shape: Shape3D

var ball_mesh := SphereMesh.new()

var ball_shape := SphereShape3D.new()

func _ready() -> void:
	# Spawn the player at start with its default components

	var controller_comp_p1 := Components.Controller.new()
	controller_comp_p1.forward_key = KEY_W
	controller_comp_p1.backward_key = KEY_S
	controller_comp_p1.left_key = KEY_A
	controller_comp_p1.right_key = KEY_D
	controller_comp_p1.jump_key = KEY_SPACE
	controller_comp_p1.dash_key = KEY_SHIFT
	controller_comp_p1.hit_key = KEY_F
	self._make_player(controller_comp_p1)

	# Second player for testing
	var controller_comp_p2 := Components.Controller.new()
	controller_comp_p2.forward_key = KEY_UP
	controller_comp_p2.backward_key = KEY_DOWN
	controller_comp_p2.left_key = KEY_LEFT
	controller_comp_p2.right_key = KEY_RIGHT
	controller_comp_p2.jump_key = KEY_ALT
	controller_comp_p2.dash_key = KEY_CTRL
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
	
	self._make_ball()


func _make_ball() -> void:
	var ball : RID = FlecsScene.create_raw_entity_with_name("Ball")
	var mesh_comp := Components.MeshComponent.new(ball_mesh, self.get_viewport().world_3d)
	var xform := Transform3D(Basis(), Vector3(0, 5, -3))
	var body := Components.PhysicsBody.new(ball_shape, self.get_viewport().world_3d, xform)
	body.set_bounciness(0.7)
	body.set_gravity_scale(0.1)
	var bag_comp := Components.Bag.new()

	FlecsScene.entity_add_component_instance(ball, Components.PhysicsBody.get_type_name(), body)
	FlecsScene.entity_add_component_instance(ball, Components.MeshComponent.get_type_name(), mesh_comp)
	FlecsScene.entity_add_component_instance(ball, Components.Bag.get_type_name(), bag_comp)


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


func _process(delta: float) -> void:
	pass
