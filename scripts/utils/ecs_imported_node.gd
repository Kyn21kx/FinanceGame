class_name ECSImportedNode extends Node3D

func _ready() -> void:
	EditorImporterSystem.instance.nodes_to_save.append(self)
	pass
