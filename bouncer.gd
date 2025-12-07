class_name Bouncer extends CSGSphere3D

var launch_node: Node3D

func _ready() -> void:
	self.launch_node = self.get_child(0)
