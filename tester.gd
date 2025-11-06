@tool
extends Node

@export_tool_button("Generate mesh and gizmo", "Callable") var btn := self.generate_mesh

@export var prefab_test: PackedScene

func generate_mesh() -> void:
	var world : World3D = null
	if Engine.is_editor_hint():
		var root_node := EditorInterface.get_edited_scene_root()
		world = root_node.get_viewport().find_world_3d()
	else:
		world = self.get_viewport().world_3d

	# ModelECSCreator.create_model_entity(prefab_test, world)
	var gizmo_entity : RID = FlecsScene.create_raw_entity_with_tag("Gizmo")
	var spawn_event = FlecsScene.create_raw_entity_with_tag("GIZMO_SPAWNED")
	var parts : Dictionary = GizmoUtils.create_translation_gizmo_parts(world, gizmo_entity, 1.5)
	FlecsScene.entity_emit(gizmo_entity, spawn_event, parts)
	print("Emitted!")

	# var gizmo_mesh : ArrayMesh = ModelECSCreator.create_axis_line_mesh(10)
	# var mesh_inst := MeshInstance3D.new()
	# mesh_inst.mesh = gizmo_mesh
	# self.add_child(mesh_inst)
	# var mesh_comp := Components.MeshComponent.new(gizmo_mesh, world)
	# var xform := Transform3D()

	# FlecsScene.entity_add_component_instance(gizmo_entity, Components.MeshComponent.get_type_name(), mesh_comp)
	# FlecsScene.entity_add_component_instance(gizmo_entity, "Transform3D", xform)
	# print("Gizmo entity: ", gizmo_entity)


# func _serialize_components():
# 	var test : RID = FlecsScene.create_raw_entity_with_name("Some entity")

# 	FlecsScene.register_gdscript_primitive_component_serializer("proximity_radius", TYPE_FLOAT)
# 	FlecsScene.register_gdscript_primitive_component_serializer("proximity_text", TYPE_STRING)
# 	FlecsScene.register_gdscript_primitive_component_serializer("BRECEFPos", TYPE_VECTOR3)

# 	FlecsScene.entity_add_component_instance(test, "proximity_radius", 500.0)
# 	FlecsScene.entity_add_component_instance(test, "proximity_text", "I am near you!!!!!")
# 	FlecsScene.entity_add_component_instance(test, "BRECEFPos", Vector3(-3030350, 4922560, 2695770))


# 	FlecsScene.save_scene("res://world.json")
# 	FlecsScene.load_scene("res://world.json")
# 	FlecsScene.save_scene("res://world.json")

# 	pass


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# self._serialize_components()
	self.generate_mesh()
	pass
