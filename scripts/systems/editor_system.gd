@tool
extends Control
class_name EditorSystem

var registered_components := [
	Components.Dash,
	Components.Movement,
	Components.Controller
]

var dropdown: OptionButton

func _ready() -> void:
	print("Hey")
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

func _process(delta: float):
	pass

func option_dropdown():
	# Create the dropdown
	dropdown = OptionButton.new()
	dropdown.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	safe_add_child(dropdown)
	
	# Populate dropdown with components
	populate_dropdown()
	
	# Connect the dropdown signal
	# dropdown.item_selected.connect(_on_dropdown_selected)
	
	# Create the button
	var create_button = Button.new()
	create_button.text = "Create Component"
	# create_button.pressed.connect(_on_create_component)
	safe_add_child(create_button)
	
	# Set up layout
	var vbox = VBoxContainer.new()
	safe_add_child_to(vbox, dropdown)
	safe_add_child_to(vbox, create_button)
	safe_add_child(vbox)


func populate_dropdown():
	dropdown.clear()
	for component in registered_components:
		dropdown.add_item(component.get_type_name())
	
	# Add a default empty option at index 0
	dropdown.add_item("Select a component...", 0)
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
	
	# Add property label
	var label = Label.new()
	label.text = prop_name.capitalize() + ":"
	label.custom_minimum_size.x = 120
	safe_add_child_to(hbox, label)
	
	# Create appropriate input control based on type
	var input_control: Control
	
	match type:
		TYPE_BOOL:
			input_control = _create_bool_input(current_value)
		
		TYPE_INT:
			input_control = _create_int_input(current_value)
		
		TYPE_FLOAT:
			input_control = _create_float_input(current_value)
		
		TYPE_STRING:
			input_control = _create_string_input(current_value)
		
		TYPE_VECTOR2:
			input_control = _create_vector2_input(current_value)
		
		TYPE_VECTOR3:
			input_control = _create_vector3_input(current_value)
		
		TYPE_VECTOR4:
			input_control = _create_vector4_input(current_value)
		
		_:
			# Fallback for unsupported types
			input_control = _create_string_input(str(current_value))
	
	safe_add_child_to(hbox, input_control)
	
	# Connect the input to update the component property
	# _connect_input_to_property(input_control, comp_instance, prop_name, type)

func _create_bool_input(value: bool) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	return checkbox

func _create_int_input(value: int) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	return spinbox

func _create_float_input(value: float) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 0.1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	return spinbox

func _create_string_input(value: String) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size.x = 150
	return line_edit

func _create_vector2_input(value: Vector2) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var x_input = SpinBox.new()
	x_input.step = 0.1
	x_input.allow_greater = true
	x_input.allow_lesser = true
	x_input.value = value.x
	x_input.custom_minimum_size.x = 80
	
	var y_input = SpinBox.new()
	y_input.step = 0.1
	y_input.allow_greater = true
	y_input.allow_lesser = true
	y_input.value = value.y
	y_input.custom_minimum_size.x = 80
	
	container.add_child(x_input)
	container.add_child(y_input)
	
	return container

func _create_vector3_input(value: Vector3) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var x_input = SpinBox.new()
	x_input.step = 0.1
	x_input.allow_greater = true
	x_input.allow_lesser = true
	x_input.value = value.x
	x_input.custom_minimum_size.x = 70
	
	var y_input = SpinBox.new()
	y_input.step = 0.1
	y_input.allow_greater = true
	y_input.allow_lesser = true
	y_input.value = value.y
	y_input.custom_minimum_size.x = 70
	
	var z_input = SpinBox.new()
	z_input.step = 0.1
	z_input.allow_greater = true
	z_input.allow_lesser = true
	z_input.value = value.z
	z_input.custom_minimum_size.x = 70
	
	container.add_child(x_input)
	container.add_child(y_input)
	container.add_child(z_input)
	
	return container

func _create_vector4_input(value: Vector4) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	for i in range(4):
		var input = SpinBox.new()
		input.step = 0.1
		input.allow_greater = true
		input.allow_lesser = true
		input.value = value[i]
		input.custom_minimum_size.x = 60
		container.add_child(input)
	
	return container
