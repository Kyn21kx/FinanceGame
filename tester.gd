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


func get_viewport_consistent() -> Viewport:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_viewport_3d()
	return self.get_viewport()


func get_world3d_consistent() -> World3D:
	return self.get_viewport_consistent().find_world_3d()

func copy_ecs_data():
	var registered_components := [
		Components.Dash,
		Components.Movement,
		Components.Controller,
		Components.Player,
		Components.Throwable,
		Components.Thrower,
		Components.PhysicsBody
	]
	# TODO: make into a map
	var registered_components_name := [
		Components.Dash.get_type_name(),
		Components.Movement.get_type_name(),
		Components.Controller.get_type_name(),
		Components.Player.get_type_name(),
		Components.Throwable.get_type_name(),
		Components.Thrower.get_type_name(),
		Components.PhysicsBody.get_type_name()
	]
	# Walk through the global node data (just a file), get the 
	var file := FileAccess.open("res://comp_data.json", FileAccess.READ)
	var json : String = file.get_as_text()
	var comp_data: Dictionary = JSON.parse_string(json)

	for node_path: String in comp_data.keys():
		var entity : RID = FlecsScene.create_raw_entity()
		var node_instance : Node = get_node(NodePath(node_path))
		assert(node_instance != null, "Node path not found, forgot to save?")
		var is_mesh_instance : bool = node_instance is MeshInstance3D
		if is_mesh_instance:
			# Add a mesh component
			var mesh_instance := node_instance as MeshInstance3D
			var mesh_comp := Components.MeshComponent.new(mesh_instance.mesh, self.get_world3d_consistent())
			FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
		var comp_dict : Dictionary = comp_data[node_path]
		for comp_key in comp_dict:
			# Find index??
			var index = registered_components_name.find(comp_key)

			var instance = null
			var is_physics_body_and_targetting_mesh : bool = registered_components_name[index] == Components.PhysicsBody.get_type_name() and is_mesh_instance
			if is_physics_body_and_targetting_mesh:
				# Get shape of the MeshInstance
				var mesh_instance := node_instance as MeshInstance3D
				var shape : Shape3D = mesh_instance.mesh.create_convex_shape()
				instance = Components.PhysicsBody.new(shape, self.get_world3d_consistent())
			else:
				instance = registered_components[index].new()
			
			var fields : Dictionary = comp_dict[comp_key]
		
			for field_key in fields:
				instance.set(field_key, fields[field_key])

			FlecsScene.entity_add_component_instance(entity, instance.get_type_name(), instance)
		# TODO: Delete note
		node_instance.queue_free()

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
		var comp_data: Dictionary = NodeComponentAdapter.instance.global_metadata


		if (comp_data.is_empty()):
			return
		var file := FileAccess.open("res://comp_data.json", FileAccess.WRITE)
		file.store_string(JSON.stringify(comp_data))
		print("Saved!")

func on_response(status: int, body: PackedByteArray):
	print("Status: ", status, "; body: ", body.get_string_from_utf8())
	pass
		
func _process(delta: float):
	if Engine.is_editor_hint():
		self.check_for_save()

		return
	self.time += delta
	var truncated: int = floori(self.time)
	if truncated % 10 == 0 && truncated != 0 && truncated != self.last_spawn:
		# var client := CurlHttpClient.create_curl_client(100)
		# client.init_client(1)
		# client.send_get("https://httpbin.org/get", on_response, {})
		self.last_spawn = truncated
	pass
