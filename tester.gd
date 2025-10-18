@tool
extends Node

@export_tool_button("Generate mesh")
var button = generate_mesh

@export var prefab_test: PackedScene

func generate_mesh() -> void:
	print("Generating!")
	var root_node := EditorInterface.get_edited_scene_root()
	print("Root node: ", root_node)
	var world : World3D = root_node.get_viewport().find_world_3d()
	print("World: ", world)
	var entity : RID = ModelECSCreator.create_model_entity(prefab_test, world)
	print("Entity: ", entity)

func _ready() -> void:
	self.generate_mesh()
	pass
