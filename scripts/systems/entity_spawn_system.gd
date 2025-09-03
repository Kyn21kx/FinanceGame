extends Node
class_name EntitySpawnSystem

# Maybe the player prefab here
@export
var player_model: Mesh

@export
var player_shape: Shape3D

func _ready() -> void:
	# Spawn the player at start with its default components
	self._make_player()
	pass

func _make_player() -> void:
	var player : RID = FlecsScene.create_raw_entity_with_name("Player")
	var mesh_comp := Components.MeshComponent.new(self.player_model, self.get_viewport().world_3d)
	FlecsScene.entity_add_component_instance(player, Components.MeshComponent.get_type_name(), mesh_comp)
	
	var physics_comp := Components.PhysicsBody.new(self.player_shape, self.get_viewport().world_3d)
	physics_comp.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X | PhysicsServer3D.BODY_AXIS_ANGULAR_Y | PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
	FlecsScene.entity_add_component_instance(player, Components.PhysicsBody.get_type_name(), physics_comp)
	
	var movement_comp := Components.Movement.new()
	movement_comp.speed = 15
	movement_comp.jump_force = 10
	FlecsScene.entity_add_component_instance(player, Components.Movement.get_type_name(), movement_comp)
	
	var controller_comp := Components.Controller.new()
	controller_comp.forward_key = KEY_W
	controller_comp.backward_key = KEY_S
	controller_comp.left_key = KEY_A
	controller_comp.right_key = KEY_D
	controller_comp.jump_key = KEY_SPACE
	controller_comp.dash_key = KEY_SHIFT
	FlecsScene.entity_add_component_instance(player, Components.Controller.get_type_name(), controller_comp)

	var dash_comp := Components.Dash.new()
	dash_comp.max_distance = 7
	dash_comp.speed = 12
	FlecsScene.entity_add_component_instance(player, Components.Dash.get_type_name(), dash_comp)
	pass

func _process(delta: float) -> void:
	pass

