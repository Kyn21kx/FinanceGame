@tool
extends EditorInspectorPlugin
class_name NodeComponentAdapter

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


static var instance: NodeComponentAdapter
var editor_interface : EditorInterface = null
var current_object : Object = null
var current_container: Control = null
var component_header_scene = preload("res://addons/component_creator/ui_components/component_header.tscn")
var current_header: ComponentEditor = null
var current_dropdown: OptionButton = null
var global_metadata: Dictionary[Node, Dictionary] = {}

func _can_handle(object: Object) -> bool:
	return object is MeshInstance3D

func safe_add_child_to(parent: Node, instance: Node):
	if (parent == null):
		print("Null parent for child: ", instance.name)
		return
	if (instance == null):
		print("Null child for parent: ", parent.name)
		return

	if (instance.get_parent() != null):
		instance.reparent(parent)
		return
	parent.add_child(instance)

func populate_dropdown(dropdown: OptionButton):
	dropdown.clear()
	dropdown.add_item("Select a component to add...", 0)
	for component in registered_components:
		dropdown.add_item(component.get_type_name())
	
	dropdown.select(0)


func render_component_properties(sample_instance):
	var comp_data: Dictionary = self.global_metadata.get_or_add(self.current_object, {})

	var fields : Dictionary = comp_data.get_or_add(sample_instance.get_type_name(), {})
	if (fields.is_empty()):
		comp_data[sample_instance.get_type_name()] = fields
	
	var props: Array = sample_instance.get_property_list()
	for prop in props:
		if prop.name in ["script", "RefCounted", "Built-in script"]:
			continue
		var static_props: Dictionary = sample_instance.get_readonly_props()
		var read_only : bool = prop.type == TYPE_RID || static_props.get(prop.name)
		fields[prop.name] = sample_instance.get(prop.name)
		print("From within loop... field: ", prop.name, "; value: ", fields[prop.name])
		var control_node : Control = render_property(sample_instance, prop.name, prop.type, read_only)
		safe_add_child_to(self.current_header, control_node)


func render_property(comp_instance, prop_name: String, type: int, is_read_only: bool = false) -> Control:
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
	
	var current_editable_node := self.current_object
	var on_change_update := func(p_val):
		var comp_data : Dictionary = self.global_metadata.get(current_editable_node)
		var fields : Dictionary = comp_data[comp_instance.get_type_name()]
		fields[prop_name] = p_val
		
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
			# Fallback for unsupported types
			input_control = UIUtils._create_string_input(str(current_value), on_change_update,  is_read_only)
	
	safe_add_child_to(hbox, input_control)
	
	return hbox

func on_component_selected(item: int):
	if item < 1 || item > self.registered_components.size():
		# Print a warning or something
		return
	var comp_instance = self.registered_components[item - 1].new()
	self.current_header = self.component_header_scene.instantiate() as ComponentEditor
	self.current_header.set_comp_name(comp_instance.get_type_name())

	safe_add_child_to(self.current_container, self.current_header)
	
	render_component_properties(comp_instance)
	self.current_dropdown.select(0)

func fetch_component_data() -> void:
	var comp_data : Dictionary = self.global_metadata
	if (comp_data.is_empty()):
		return
	for comp_dict: Dictionary in comp_data.values():
		for comp_key in comp_dict:
			print("Trying to instantiate ", comp_key)
			# Find index??
			var index = self.registered_components_name.find(comp_key)
			var instance = self.registered_components[index].new()
			print("Instance at runtime? ", instance)
			var fields : Dictionary = comp_dict[comp_key]
			print(fields)
			
			self.current_header = self.component_header_scene.instantiate() as ComponentEditor
			self.current_header.set_comp_name(instance.get_type_name())

			safe_add_child_to(self.current_container, self.current_header)
			
			for field_key in fields:
				instance.set(field_key, fields[field_key])
			render_component_properties(instance)


func option_dropdown() -> Control:
	var dropdown := OptionButton.new()
	dropdown.item_selected.connect(on_component_selected)
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	# Populate dropdown with components
	populate_dropdown(dropdown)

	return dropdown

func _init() -> void:
	instance = self

func _parse_begin(_object: Object) -> void:
	self.current_object = _object
	if (self.current_object == null):
		print("Current object is null!")
		return
	var comp_data: Dictionary = self.global_metadata.get_or_add(self.current_object, {})
	print("Comp data: ", comp_data)
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

