@tool
extends Control
class_name ComponentEditor

func _ready() -> void:
	%DeleteButton.pressed.connect(delete_component)
	%NameLabel.label_settings = LabelSettings.new()
	%NameLabel.label_settings.font_size = 24

 
func set_comp_name(name: StringName) -> void:
	%NameLabel.text = name


func delete_component() -> void:
	self.queue_free()
