@tool
class_name NodelessGizmoPlugin
extends EditorNode3DGizmoPlugin


func _init() -> void:
	create_material("main", Color(1, 0, 0))
	create_handle_material("handles")


func _has_gizmo(for_node: Node3D) -> bool:
	#return for_node is EntitySpawnSystem  # Your node with Vector3 property
	return false

func _get_handle_value(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> Variant:
	# return gizmo.get_node_3d().my_vector3
	return gizmo.get_node_3d().sample_pos

func _get_gizmo_name() -> String:
	return "Nodeless Gizmo"

# func _redraw(gizmo: EditorNode3DGizmo) -> void:
# 	gizmo.clear()
# 	#var node = gizmo.get_node_3d() as EntitySpawnSystem
# 	#if not node:
# 	#	return

# 	# Draw a small sphere at the Vector3 position
# 	var sphere := SphereMesh.new()
# 	sphere.radius = 0.1
# 	sphere.height = 0.2
# 	sphere.material = get_material("main", gizmo)
# 	# gizmo.add_mesh(sphere, get_material("main", gizmo), Transform3D(Basis(), node.global_position))

# 	# Add a line from node origin to the Vector3 position for visibility
# 	var lines := PackedVector3Array([Vector3.ZERO, node.global_position])
# 	gizmo.add_lines(lines, get_material("main", gizmo))

# 	# Add handles for dragging (one for each axis)

# 	gizmo.add_handles([node.sample_pos], get_material("handles", gizmo), [], false)	


# func _set_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, camera: Camera3D, screen_pos: Vector2) -> void:
# 	var node = gizmo.get_node_3d() as EntitySpawnSystem
# 	if not node:
# 		return

# 	# Get the camera's ray origin and direction from the screen position
# 	var ray_origin = camera.global_position
# 	var ray_dir = camera.project_ray_normal(screen_pos)

# 	# Define a plane perpendicular to the axis being dragged, passing through the current target_position
# 	var global_pos = node.global_transform * node.sample_pos
# 	var plane_normal: Vector3
# 	match handle_id:
# 		0: plane_normal = (node.global_transform.basis * Vector3(1, 0, 0)).normalized()  # X axis
# 		1: plane_normal = (node.global_transform.basis * Vector3(0, 1, 0)).normalized()  # Y axis
# 		2: plane_normal = (node.global_transform.basis * Vector3(0, 0, 1)).normalized()  # Z axis

# 	var plane = Plane(plane_normal, global_pos.dot(plane_normal))

# 	# Intersect the camera ray with the plane to get the new 3D position
# 	var new_global_pos = plane.intersects_ray(ray_origin, ray_dir)
# 	if new_global_pos:
# 		# Convert back to local space
# 		var new_local_pos = node.global_transform.affine_inverse() * new_global_pos
# 		match handle_id:
# 			0: node.sample_pos.x = new_local_pos.x  # Update only X
# 			1: node.sample_pos.y = new_local_pos.y  # Update only Y
# 			2: node.sample_pos.z = new_local_pos.z  # Update only Z
# 		node.notify_property_list_changed()  # Update Inspector

# func _commit_handle(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool, restore: Variant, cancel: bool) -> void:
# 	var node = gizmo.get_node_3d() as EntitySpawnSystem
# 	if cancel:
# 		node.target_position = restore
# 	else:
# 		# Push undo action
# 		var undo_redo = get_undo_redo()
# 		undo_redo.create_action("Move Vector3")
# 		undo_redo.add_do_property(node, "target_position", node.target_position)
# 		undo_redo.add_undo_property(node, "target_position", restore)
# 		undo_redo.commit_action()

func _get_handle_name(gizmo: EditorNode3DGizmo, handle_id: int, secondary: bool) -> String:
	match handle_id:
		0: return "X Axis"
		1: return "Y Axis"
		2: return "Z Axis"
	return ""
