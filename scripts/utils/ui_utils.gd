class_name UIUtils


static func _create_bool_input(value: bool) -> CheckBox:
	var checkbox = CheckBox.new()
	checkbox.button_pressed = value
	return checkbox

static func _create_int_input(value: int) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	return spinbox

static func _create_float_input(value: float) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 0.1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	return spinbox

static func _create_string_input(value: String) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size.x = 150
	return line_edit

static func _create_vector2_input(value: Vector2) -> HBoxContainer:
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

static func _create_vector3_input(value: Vector3) -> HBoxContainer:
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

static func _create_vector4_input(value: Vector4) -> HBoxContainer:
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
