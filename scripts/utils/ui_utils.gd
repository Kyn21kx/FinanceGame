
# UIUtils.gd
class_name UIUtils


const SERIALIZE_CUSTOM_CONTROL := "serialize_to_custom_control"

# All factories now require a non-null Callable on_change argument.
# on_change.call(new_value) will be invoked with the full Variant value.

static func _create_bool_input(value: bool, on_change: Callable, _is_read_only: bool = false) -> CheckBox:
	var checkbox := CheckBox.new()
	checkbox.toggle_mode = true
	checkbox.button_pressed = value
	checkbox.disabled = _is_read_only
	checkbox.toggled.connect(func(pressed: bool):
		on_change.call(pressed)
	)
	return checkbox

static func _create_int_input(value: int, on_change: Callable, _is_read_only: bool = false) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	spinbox.editable = !_is_read_only
	spinbox.value_changed.connect(func(v):
		on_change.call(int(v))
	)
	return spinbox

static func _create_float_input(value: float, on_change: Callable, _is_read_only: bool = false) -> SpinBox:
	var spinbox = SpinBox.new()
	spinbox.step = 0.1
	spinbox.allow_greater = true
	spinbox.allow_lesser = true
	spinbox.value = value
	spinbox.editable = !_is_read_only
	spinbox.value_changed.connect(func(v):
		on_change.call(float(v))
	)
	return spinbox

static func _create_string_input(value: String, on_change: Callable, _is_read_only: bool = false) -> LineEdit:
	var line_edit = LineEdit.new()
	line_edit.text = value
	line_edit.custom_minimum_size.x = 150
	line_edit.editable = !_is_read_only
	line_edit.text_changed.connect(func(text: String):
		on_change.call(text)
	)
	return line_edit

static func _create_vector2_input(value: Vector2, on_change: Callable, _is_read_only: bool = false) -> HBoxContainer:
	var container = HBoxContainer.new()

	var x_input := SpinBox.new()
	x_input.step = 0.1
	x_input.allow_greater = true
	x_input.allow_lesser = true
	x_input.value = value.x
	x_input.editable = !_is_read_only
	x_input.custom_minimum_size.x = 80

	var y_input := SpinBox.new()
	y_input.step = 0.1
	y_input.allow_greater = true
	y_input.allow_lesser = true
	y_input.value = value.y
	y_input.editable = !_is_read_only
	y_input.custom_minimum_size.x = 80

	var lambda := func _emit_v2(_val: float):
		on_change.call(Vector2(x_input.value, y_input.value))

	x_input.value_changed.connect(lambda)
	y_input.value_changed.connect(lambda)

	container.add_child(x_input)
	container.add_child(y_input)
	return container

static func _create_vector3_input(value: Vector3, on_change: Callable, _is_read_only: bool = false) -> HBoxContainer:
	var container = HBoxContainer.new()

	var x_input := SpinBox.new()
	x_input.step = 0.1
	x_input.allow_greater = true
	x_input.allow_lesser = true
	x_input.value = value.x
	x_input.editable = !_is_read_only
	x_input.custom_minimum_size.x = 70

	var y_input := SpinBox.new()
	y_input.step = 0.1
	y_input.allow_greater = true
	y_input.allow_lesser = true
	y_input.value = value.y
	y_input.editable = !_is_read_only
	y_input.custom_minimum_size.x = 70

	var z_input := SpinBox.new()
	z_input.step = 0.1
	z_input.allow_greater = true
	z_input.allow_lesser = true
	z_input.value = value.z
	z_input.editable = !_is_read_only
	z_input.custom_minimum_size.x = 70

	var lambda := func _emit_v3(_val: float):
		on_change.call(Vector3(x_input.value, y_input.value, z_input.value))

	x_input.value_changed.connect(lambda)
	y_input.value_changed.connect(lambda)
	z_input.value_changed.connect(lambda)

	container.add_child(x_input)
	container.add_child(y_input)
	container.add_child(z_input)
	return container

static func _create_shape3d_input(value: Shape3D, on_change: Callable, _is_read_only: bool = false) -> HBoxContainer:
	var container = HBoxContainer.new()
	
	# Label showing current shape resource
	var resource_label = Label.new()
	resource_label.custom_minimum_size.x = 200
	resource_label.clip_text = true
	if value != null:
		resource_label.text = value.resource_path if value.resource_path != "" else "<%s>" % value.get_class()
	else:
		resource_label.text = "(No Shape)"
	
	container.add_child(resource_label)
	
	if not _is_read_only:
		# Button to open file dialog
		var select_button = Button.new()
		select_button.text = "Select..."
		select_button.custom_minimum_size.x = 80
		
		select_button.pressed.connect(func():
			var file_dialog = EditorFileDialog.new() if Engine.is_editor_hint() else FileDialog.new()
			file_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
			file_dialog.access = FileDialog.ACCESS_RESOURCES
			file_dialog.add_filter("*.tres, *.res", "Resource Files")
			
			file_dialog.file_selected.connect(func(path: String):
				var loaded_resource = load(path)
				if loaded_resource is Shape3D:
					resource_label.text = path
					on_change.call(loaded_resource)
				else:
					push_error("Selected resource is not a Shape3D")
				file_dialog.queue_free()
			)
			
			file_dialog.canceled.connect(func():
				file_dialog.queue_free()
			)
			
			container.add_child(file_dialog)
			file_dialog.popup_centered_ratio(0.6)
		)
		
		container.add_child(select_button)
		
		# Clear button
		var clear_button = Button.new()
		clear_button.text = "Clear"
		clear_button.custom_minimum_size.x = 60
		
		clear_button.pressed.connect(func():
			resource_label.text = "(No Shape)"
			on_change.call(null)
		)
		
		container.add_child(clear_button)
	
	return container
