@tool
extends Node

@export_tool_button("Generate mesh and gizmo", "Callable") var btn := self.generate_mesh

@export var prefab_test: PackedScene
var time: float = 0
var last_spawn: int = 0

func _add_to_gizmo_recursive(entity: RID):
	FlecsScene.entity_add_child(Globals.GIZMO_ID, entity)
	# Temporary relation that will be removed
	FlecsScene.entity_add_relation(Globals.GIZMO_ID, Relationships.MANIPULATING, entity)
	FlecsScene.entity_each_child(entity, self._add_to_gizmo_recursive)

func generate_mesh() -> void:
	var world : World3D = null
	if Engine.is_editor_hint():
		var root_node := EditorInterface.get_edited_scene_root()
		world = root_node.get_viewport().find_world_3d()
	else:
		world = self.get_viewport().world_3d

	# ModelECSCreator.create_model_entity(prefab_test, world)
	Globals.GIZMO_ID = FlecsScene.create_raw_entity_with_tag("Gizmo")
	var spawn_event = FlecsScene.create_raw_entity_with_tag("GIZMO_SPAWNED")
	var parts : Dictionary = GizmoUtils.create_translation_gizmo_parts(Vector3.ZERO, world, 1.5)
	FlecsScene.entity_emit(Globals.GIZMO_ID, spawn_event, parts)
	var model_entity : RID = ModelECSCreator.create_model_entity(self.prefab_test, world)
	FlecsScene.entity_each_child(model_entity, self._add_to_gizmo_recursive)


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	# self._serialize_components()
	self.generate_mesh()
	pass

func _process(delta: float):
	if Engine.is_editor_hint():
		return
	self.time += delta
	var truncated: int = floori(self.time)
	if truncated % 10 == 0 && truncated != 0 && truncated != self.last_spawn:
		self.generate_mesh()
		self.last_spawn = truncated
	pass
