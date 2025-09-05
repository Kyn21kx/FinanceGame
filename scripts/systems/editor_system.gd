@tool
extends Control
class_name EditorSystem

var registered_components := [
	Components.Dash,
	Components.Movement,
	Components.Controller
]

var dropdown: OptionButton
@export
var vbox_container: VBoxContainer

@export
var add_entity_text: TextEdit

@export
var add_entity_btn: Button

@export
var entities_panel: Control

var component_controls: Array[Control]

func _ready() -> void:
	FlecsScene.on_named_entity_added(_on_entity_added)
	add_entity_btn.pressed.connect(on_entity_add_button_clicked)
	option_dropdown()

func safe_add_child(instance: Node):
	if (instance.get_parent() != null):
		instance.reparent(self)
		return
	self.add_child(instance)

func safe_add_child_to(parent: Node, instance: Node):
	if (instance.get_parent() != null):
		instance.reparent(parent)
		return
	parent.add_child(instance)

func on_entity_add_button_clicked():
	FlecsScene.create_raw_entity_with_name(add_entity_text.text)
	add_entity_text.text = ""

func _on_entity_added(entity: RID, entity_name: String):
	print("The entity ", entity, " was added with the entity_name ", entity_name)
	# Add it to a scene hierarchy-like scrollable panel for later selection
	var entity_button := Button.new()
	entity_button.text = str(entity) + " - " + entity_name
	self.entities_panel.add_child(entity_button)
	# TODO: Maybe do this every few minutes/big changes instead of every change
	# FlecsScene.save_scene("res://world.json")


func on_component_selected(item: int):
	if item < 1 || item > self.registered_components.size():
		# Print a warning or something
		return
	var comp_instance = self.registered_components[item - 1].new()
	for control: Control in self.component_controls:
		control.queue_free()
	self.component_controls.clear()
	# First let's render the name
	var label := Label.new()
	label.text = comp_instance.get_type_name()
	label.label_settings = LabelSettings.new()
	label.label_settings.font_size = 24

	safe_add_child_to(self.vbox_container, label)
	self.component_controls.append(label)
	
	render_component_properties(comp_instance, self.vbox_container)
	pass

func option_dropdown():
	# Create the dropdown
	
	dropdown = OptionButton.new()
	dropdown.item_selected.connect(on_component_selected)
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_add_child(dropdown)
	
	# Populate dropdown with components
	populate_dropdown()
	
	
	# Create the button
	var create_button = Button.new()
	create_button.text = "Add component"
	# create_button.pressed.connect(_on_create_component)
	safe_add_child(create_button)
	
	# Set up layout
	safe_add_child_to(self.vbox_container, dropdown)
	safe_add_child_to(self.vbox_container, create_button)


func populate_dropdown():
	dropdown.clear()
	dropdown.add_item("Select a component to add...", 0)
	for component in registered_components:
		dropdown.add_item(component.get_type_name())
	
	dropdown.select(0)

func render_component_properties(sample_instance, container: Control):
	var props: Array = sample_instance.get_property_list()
	for prop in props:
		if prop.name in ["script", "RefCounted", "Built-in script"]:
			continue
		render_property(sample_instance, prop.name, prop.type, container)

func render_property(comp_instance, prop_name: String, type: int, container: Control):
	var current_value = comp_instance.get(prop_name)
	
	# Create a horizontal container for label + input
	var hbox = HBoxContainer.new()
	safe_add_child_to(container, hbox)
	
	var label = Label.new()
	label.text = prop_name.capitalize() + ":"
	label.custom_minimum_size.x = 120
	safe_add_child_to(hbox, label)
	
	# Create appropriate input control based on type
	var input_control: Control
	
	match type:
		TYPE_BOOL:
			input_control = UIUtils._create_bool_input(current_value)
		
		TYPE_INT:
			input_control = UIUtils._create_int_input(current_value)
		
		TYPE_FLOAT:
			input_control = UIUtils._create_float_input(current_value)
		
		TYPE_STRING:
			input_control = UIUtils._create_string_input(current_value)
		
		TYPE_VECTOR2:
			input_control = UIUtils._create_vector2_input(current_value)
		
		TYPE_VECTOR3:
			input_control = UIUtils._create_vector3_input(current_value)
		
		TYPE_VECTOR4:
			input_control = UIUtils._create_vector4_input(current_value)
		
		_:
			# Fallback for unsupported types
			input_control = UIUtils._create_string_input(str(current_value))
	
	safe_add_child_to(hbox, input_control)
	
	self.component_controls.append(hbox)
	# Connect the input to update the component property
	# _connect_input_to_property(input_control, comp_instance, prop_name, type)
