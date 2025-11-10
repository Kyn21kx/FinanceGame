class_name UIUtils

static func _create_bool_input(value: bool, _is_read_only: bool = false) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	checkbox.disabled = _is_read_only
	return checkbox

static func _create_int_input(value: int, _is_read_only: bool = false) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	spinbox.editable = !_is_read_only
	return spinbox

static func _create_float_input(value: float, _is_read_only: bool = false) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 0.1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	spinbox.editable = !_is_read_only
	return spinbox

static func _create_string_input(value: String, _is_read_only: bool = false) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size.x = 150
	line_edit.editable = !_is_read_only
	return line_edit

static func _create_vector2_input(value: Vector2, _is_read_only: bool = false) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var x_input := _create_float_input(value.x, _is_read_only)
	x_input.custom_minimum_size.x = 80
	
	var y_input := _create_float_input(value.y, _is_read_only)
	y_input.custom_minimum_size.x = 80
	
	container.add_child(x_input)
	container.add_child(y_input)
	
	return container

static func _create_vector3_input(value: Vector3, _is_read_only: bool = false) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	var x_input := _create_float_input(value.x, _is_read_only)
	x_input.custom_minimum_size.x = 70
	
	var y_input := _create_float_input(value.y, _is_read_only)
	y_input.custom_minimum_size.x = 70
	

	var z_input := _create_float_input(value.z, _is_read_only)
	z_input.custom_minimum_size.x = 70
	
	container.add_child(x_input)
	container.add_child(y_input)
	container.add_child(z_input)
	
	return container

static func _create_vector4_input(value: Vector4, _is_read_only: bool = false) -> HBoxContainer:
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
