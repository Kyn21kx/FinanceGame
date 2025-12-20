@tool
extends EditorInspectorPlugin
class_name NodeComponentAdapter


# TODO: make into a map
static var registered_components := [
	Components.Dash,
	Components.Movement,
	Components.Controller,
	Components.Player,
	Components.Throwable,
	Components.Thrower,
	Components.PhysicsBody
]
# TODO: make into a map
static var registered_components_name := [
	Components.Dash.get_type_name(),
	Components.Movement.get_type_name(),
	Components.Controller.get_type_name(),
	Components.Player.get_type_name(),
	Components.Throwable.get_type_name(),
	Components.Thrower.get_type_name(),
	Components.PhysicsBody.get_type_name()
]


static var instance: NodeComponentAdapter
var editor_interface : EditorInterface = null
var current_object : Object = null
var current_container: Control = null
var component_header_scene = preload("res://addons/component_creator/ui_components/component_header.tscn")
var current_header: ComponentEditor = null
var current_dropdown: OptionButton = null
var global_metadata: Dictionary = {}


func _can_handle(object: Object) -> bool:
	return object is MeshInstance3D or object is ECSImportedNode

func safe_add_child_to(parent: Node, p_instance: Node):
	if (parent == null):
		print("Null parent for child: ", p_instance.name)
		return
	if (p_instance == null):
		print("Null child for parent: ", parent.name)
		return

	if (p_instance.get_parent() != null):
		p_instance.reparent(parent)
		return
	parent.add_child(p_instance)

func populate_dropdown(dropdown: OptionButton):
	dropdown.clear()
	dropdown.add_item("Select a component to add...", 0)
	for component in registered_components:
		dropdown.add_item(component.get_type_name())
	
	dropdown.select(0)


func render_component_properties(sample_instance):
	var root := (self.current_object as Node).get_tree().edited_scene_root
	var path : NodePath = root.get_path_to(self.current_object as Node)
	var comp_data: Dictionary = self.global_metadata.get_or_add(str(path), {})

	var fields : Dictionary = comp_data.get_or_add(sample_instance.get_type_name(), {})
	if (fields.is_empty()):
		comp_data[sample_instance.get_type_name()] = fields
	
	var props: Array = sample_instance.get_property_list()
	for prop in props:
		var prop_name: String = prop.name
		if prop_name in ["script", "RefCounted", "Built-in script"] or prop_name.begins_with("_"):
			continue
		var static_props: Dictionary = sample_instance.get_readonly_props()
		var read_only : bool = prop.type == TYPE_RID || static_props.get(prop_name)
		fields[prop_name] = serialize_to_dict(sample_instance.get(prop_name))
		var control_node : Control = render_property(sample_instance, prop_name, prop.type, read_only)
		safe_add_child_to(self.current_header, control_node)

func serialize_to_dict(value):
	if value is Resource:
		# Save the path to the resource in the dictionary, not its string value
		return value.resource_path
	return value

func render_property(comp_instance: Object, prop_name: String, type: int, is_read_only: bool = false) -> Control:
	var current_value = comp_instance.get(prop_name)
	
	# Create a horizontal container for label + input
	var hbox = HBoxContainer.new()
	safe_add_child_to(self.current_header, hbox)
	
	var label = Label.new()
	label.text = prop_name.capitalize() + ":"
	label.custom_minimum_size.x = 120
	if is_read_only:
		label.text += " (Read Only)"
	safe_add_child_to(hbox, label)
	
	# Create appropriate input control based on type
	var input_control: Control
	
	var current_editable_node := self.current_object as Node
	var on_change_update := func(p_val):
		var root := current_editable_node.get_tree().edited_scene_root
		var relative_path : NodePath = root.get_path_to(current_editable_node)
		var comp_data : Dictionary = self.global_metadata.get(str(relative_path))
		var fields : Dictionary = comp_data[comp_instance.get_type_name()]
		fields[prop_name] = serialize_to_dict(p_val)
		comp_instance.set(prop_name, p_val)
		
	match type:
		TYPE_BOOL:
			input_control = UIUtils._create_bool_input(current_value, on_change_update, is_read_only)
		
		TYPE_INT:
			input_control = UIUtils._create_int_input(current_value, on_change_update, is_read_only)
		
		TYPE_FLOAT:
			input_control = UIUtils._create_float_input(current_value, on_change_update, is_read_only)
		
		TYPE_STRING:
			input_control = UIUtils._create_string_input(current_value, on_change_update, is_read_only)
		
		TYPE_VECTOR2:
			input_control = UIUtils._create_vector2_input(current_value, on_change_update, is_read_only)
		
		TYPE_VECTOR3:
			input_control = UIUtils._create_vector3_input(current_value, on_change_update, is_read_only)
		_:
			if comp_instance.has_method(UIUtils.SERIALIZE_CUSTOM_CONTROL):
				input_control = comp_instance.call(UIUtils.SERIALIZE_CUSTOM_CONTROL, current_value, on_change_update, is_read_only)
			else:
				input_control = UIUtils._create_string_input(str(current_value), on_change_update,  is_read_only)
	
	safe_add_child_to(hbox, input_control)
	
	return hbox


func get_viewport_consistent() -> Viewport:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_viewport_3d()
	return self.current_object.get_viewport()


func get_world3d_consistent() -> World3D:
	return self.get_viewport_consistent().find_world_3d()

func on_component_selected(item: int):
	if item < 1 || item > registered_components.size():
		# Print a warning or something
		return
	var comp_instance = null
	var is_physics_body_and_targetting_mesh : bool = registered_components_name[item - 1] == Components.PhysicsBody.get_type_name() and self.current_object is MeshInstance3D
	if is_physics_body_and_targetting_mesh:
		# Get shape of the MeshInstance
		var mesh_instance := self.current_object as MeshInstance3D
		var shape : Shape3D = mesh_instance.mesh.create_convex_shape()
		comp_instance = Components.PhysicsBody.new(shape)
	else:
		comp_instance = registered_components[item - 1].new()
	self.current_header = self.component_header_scene.instantiate() as ComponentEditor
	self.current_header.set_comp_name(comp_instance.get_type_name())

	safe_add_child_to(self.current_container, self.current_header)
	
	render_component_properties(comp_instance)
	self.current_dropdown.select(0)

func fetch_component_data() -> void:
	var comp_data : Dictionary = self.global_metadata
	if (comp_data.is_empty()):
		return
	for node_path: String in comp_data.keys():
		var current_node : Node = (self.current_object as Node)
		var comp_node : Node = current_node.get_tree().edited_scene_root.get_node(NodePath(node_path))
		if current_node != comp_node:
			continue
		var comp_dict: Dictionary = comp_data[node_path]
		for comp_key in comp_dict:
			# Find index??
			var index = registered_components_name.find(comp_key)
			
			var is_physics_body_and_targetting_mesh : bool = registered_components_name[index] == Components.PhysicsBody.get_type_name() and self.current_object is MeshInstance3D
			var comp_instance = null
			if is_physics_body_and_targetting_mesh:
				# Get shape of the MeshInstance
				var mesh_instance := self.current_object as MeshInstance3D
				var shape : Shape3D = mesh_instance.mesh.create_convex_shape()
				comp_instance = Components.PhysicsBody.new(shape)
			else:
				comp_instance = registered_components[index].new()
			
			var fields : Dictionary = comp_dict[comp_key]
			
			self.current_header = self.component_header_scene.instantiate() as ComponentEditor
			self.current_header.set_comp_name(comp_instance.get_type_name())

			safe_add_child_to(self.current_container, self.current_header)
			
			for field_key in fields:
				comp_instance.set(field_key, fields[field_key])
			render_component_properties(comp_instance)


func option_dropdown() -> Control:
	var dropdown := OptionButton.new()
	dropdown.item_selected.connect(on_component_selected)
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Populate dropdown with components
	populate_dropdown(dropdown)

	return dropdown

func _init() -> void:
	instance = self
	# Load the data from the file
	var file := FileAccess.open("res://comp_data.json", FileAccess.READ)
	if (file == null):
		return
	var json : String = file.get_as_text()
	var parsed_json = JSON.parse_string(json)
	if (parsed_json == null):
		return
	self.global_metadata = JSON.parse_string(json) as Dictionary

func _parse_begin(_object: Object) -> void:
	self.current_object = _object
	if (self.current_object == null):
		print("Current object is null!")
		return
	var root : Node = (self.current_object as Node).get_tree().edited_scene_root
	var path := root.get_path_to(self.current_object as Node)
	self.global_metadata.get_or_add(str(path), {})
	var label := Label.new()
	label.text = "This object will be saved in the ECS simulation!"
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 24
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	self.add_custom_control(label)
	self.current_container = VBoxContainer.new()
	self.fetch_component_data()
	self.current_dropdown = self.option_dropdown()
	self.current_container.add_child(self.current_dropdown)
	self.add_custom_control(self.current_container)
