@tool
extends Node

@export_tool_button("Generate mesh and gizmo", "Callable") var btn := self.generate_mesh

@export_tool_button("Save Scene", "Callable") var save_btn := self.save_scene
@export_tool_button("Load Scene", "Callable") var load_btn := self.load_scene

@export var prefab_test: PackedScene
var time: float = 0
var last_spawn: int = 0

func _add_to_gizmo_recursive(entity: RID):
	FlecsScene.entity_add_child(Globals.GIZMO_ID, entity)
	# Temporary relation that will be removed
	FlecsScene.entity_add_relation(Globals.GIZMO_ID, Relationships.MANIPULATING, entity)
	FlecsScene.entity_each_child(entity, self._add_to_gizmo_recursive)

func save_scene():
	FlecsScene.save_scene("res://world.json")
	pass

func load_scene():
	FlecsScene.load_scene("res://world.json")
	pass

func copy_ecs_data():

	var registered_components := [
		Components.Dash,
		Components.Movement,
		Components.Controller,
		Components.Player,
		Components.Throwable,
		Components.Thrower
	]
	# TODO: make into a map
	var registered_components_name := [
		Components.Dash.get_type_name(),
		Components.Movement.get_type_name(),
		Components.Controller.get_type_name(),
		Components.Player.get_type_name(),
		Components.Throwable.get_type_name(),
		Components.Thrower.get_type_name()
	]
	# Walk through the global node data (just a file), get the 
	var file := FileAccess.open("res://comp_data.json", FileAccess.READ)
	var json : String = file.get_as_text()
	var comp_data: Dictionary = JSON.parse_string(json)

	for comp_dict: Dictionary in comp_data.values():
		var entity : RID = FlecsScene.create_raw_entity()
		for comp_key in comp_dict:
			# Find index??
			var index = registered_components_name.find(comp_key)
			var instance = registered_components[index].new()
			var fields : Dictionary = comp_dict[comp_key]
		
			for field_key in fields:
				instance.set(field_key, fields[field_key])

			FlecsScene.entity_add_component_instance(entity, instance.get_type_name(), instance)
	

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
	self.copy_ecs_data()
	self.generate_mesh()
	pass

func check_for_save():
	if (Input.is_key_pressed(KEY_CTRL) and Input.is_key_pressed(KEY_S)):
		print("Saving")
		var comp_data: Dictionary[Node, Dictionary] = NodeComponentAdapter.instance.global_metadata

		if (comp_data.is_empty()):
			return
		var file := FileAccess.open("res://comp_data.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(comp_data))
		print("Saved!")

		
func _process(delta: float):
	if Engine.is_editor_hint():
		self.check_for_save()

		return
	self.time += delta
	var truncated: int = floori(self.time)
	if truncated % 10 == 0 && truncated != 0 && truncated != self.last_spawn:
		self.generate_mesh()
		self.last_spawn = truncated
	pass
