@tool
class_name GizmoUtils

enum AxisType { AXIS_X, AXIS_Y, AXIS_Z }

class GizmoPartInfo:
	var entity: RID
	var axis_type: AxisType

	func _init(p_entity: RID, p_axis_type: AxisType) -> void:
		self.entity = p_entity
		self.axis_type = p_axis_type


static func create_gizmo_material(color: Color, unshaded: bool = true, on_top: bool = true) -> StandardMaterial3D:
	"""Create a material suitable for gizmo rendering"""
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	
	if unshaded:
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	
	if on_top:
		mat.no_depth_test = true
		mat.render_priority = 127
	
	return mat


static func create_line_mesh(points: PackedVector3Array) -> ArrayMesh:
	"""Create a line mesh from an array of points (pairs for line segments)"""
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = points
	
	var colors := PackedColorArray()
	colors.resize(points.size())
	colors.fill(Color.WHITE)
	arrays[Mesh.ARRAY_COLOR] = colors
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_LINES, arrays)
	return mesh


static func create_axis_line_mesh(length: float = 1.0, axis: Vector3 = Vector3.RIGHT) -> ArrayMesh:
	"""Create a simple axis line from origin"""
	var points := PackedVector3Array([Vector3.ZERO, axis * length])
	return create_line_mesh(points)


static func create_circle_mesh(radius: float = 1.0, segments: int = 32, normal: Vector3 = Vector3.UP) -> ArrayMesh:
	"""Create a circle line mesh on a plane defined by the normal"""
	var points := PackedVector3Array()
	
	# Find perpendicular vectors
	var tangent := Vector3.UP if abs(normal.dot(Vector3.UP)) < 0.9 else Vector3.RIGHT
	var bitangent := normal.cross(tangent).normalized()
	tangent = bitangent.cross(normal).normalized()
	
	for i in segments:
		var angle1 := (i * TAU) / segments
		var angle2 := ((i + 1) * TAU) / segments
		
		var p1 := (tangent * cos(angle1) + bitangent * sin(angle1)) * radius
		var p2 := (tangent * cos(angle2) + bitangent * sin(angle2)) * radius
		
		points.append(p1)
		points.append(p2)
	
	return create_line_mesh(points)


static func create_sphere_mesh(radius: float = 0.1, segments: int = 8) -> SphereMesh:
	"""Create a sphere mesh for handles"""
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = segments
	sphere.rings = segments / 2
	return sphere


static func create_box_mesh(size: float = 0.1) -> BoxMesh:
	"""Create a box mesh for handles"""
	var box := BoxMesh.new()
	box.size = Vector3.ONE * size
	return box


static func create_cone_mesh(radius: float = 0.1, height: float = 0.3, segments: int = 8) -> ArrayMesh:
	"""Create a cone mesh for arrow tips"""
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Tip of the cone at origin
	var tip := Vector3.ZERO
	
	# Base vertices
	var base_verts: Array[Vector3] = []
	for i in segments:
		var angle := (i * TAU) / segments
		var x := cos(angle) * radius
		var z := sin(angle) * radius
		base_verts.append(Vector3(x, -height, z))
	
	# Create triangles from tip to base
	for i in segments:
		var next_i := (i + 1) % segments
		
		vertices.append(tip)
		vertices.append(base_verts[i])
		vertices.append(base_verts[next_i])
		
		# Calculate normal
		var edge1 := base_verts[i] - tip
		var edge2 := base_verts[next_i] - tip
		var normal := edge1.cross(edge2).normalized()
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
	
	# Base cap
	var base_center := Vector3(0, -height, 0)
	for i in segments:
		var next_i := (i + 1) % segments
		
		vertices.append(base_center)
		vertices.append(base_verts[next_i])
		vertices.append(base_verts[i])
		
		normals.append(Vector3.DOWN)
		normals.append(Vector3.DOWN)
		normals.append(Vector3.DOWN)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func create_arrow_mesh(shaft_length: float = 0.8, cone_length: float = 0.2, shaft_radius: float = 0.02, cone_radius: float = 0.08) -> ArrayMesh:
	"""Create an arrow mesh (cylinder + cone) pointing up (Y+)"""
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var segments := 8
	
	# Shaft (cylinder along Y axis)
	for i in segments:
		var angle1 := (i * TAU) / segments
		var angle2 := ((i + 1) * TAU) / segments
		
		var x1 := cos(angle1) * shaft_radius
		var z1 := sin(angle1) * shaft_radius
		var x2 := cos(angle2) * shaft_radius
		var z2 := sin(angle2) * shaft_radius
		
		# Two triangles per segment
		var bot1 := Vector3(x1, 0, z1)
		var bot2 := Vector3(x2, 0, z2)
		var top1 := Vector3(x1, shaft_length, z1)
		var top2 := Vector3(x2, shaft_length, z2)
		
		# Triangle 1
		vertices.append(bot1)
		vertices.append(top1)
		vertices.append(bot2)
		
		var n1 := Vector3(x1, 0, z1).normalized()
		normals.append(n1)
		normals.append(n1)
		normals.append(n1)
		
		# Triangle 2
		vertices.append(bot2)
		vertices.append(top1)
		vertices.append(top2)
		
		var n2 := Vector3(x2, 0, z2).normalized()
		normals.append(n2)
		normals.append(n2)
		normals.append(n2)
	
	# Cone tip at the top
	var cone_base_y := shaft_length
	var cone_tip_y := shaft_length + cone_length
	var tip := Vector3(0, cone_tip_y, 0)
	
	for i in segments:
		var angle1 := (i * TAU) / segments
		var angle2 := ((i + 1) * TAU) / segments
		
		var x1 := cos(angle1) * cone_radius
		var z1 := sin(angle1) * cone_radius
		var x2 := cos(angle2) * cone_radius
		var z2 := sin(angle2) * cone_radius
		
		var base1 := Vector3(x1, cone_base_y, z1)
		var base2 := Vector3(x2, cone_base_y, z2)
		
		vertices.append(tip)
		vertices.append(base1)
		vertices.append(base2)
		
		var edge1 := base1 - tip
		var edge2 := base2 - tip
		var normal := edge1.cross(edge2).normalized()
		normals.append(normal)
		normals.append(normal)
		normals.append(normal)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh


static func create_line_entity(scenario: World3D, points: PackedVector3Array, material: Material, transform: Transform3D = Transform3D.IDENTITY, name: String = "GizmoLine") -> RID:
	"""Create a line entity with the given points"""
	var mesh := create_line_mesh(points)
	var entity := FlecsScene.create_raw_entity_with_name(name)
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)
	
	FlecsScene.entity_add_component_instance(entity, "Transform3D", transform)
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	
	return entity


static func create_axis_entity(scenario: World3D, length: float, axis: Vector3, material: Material, transform: Transform3D = Transform3D.IDENTITY, name: String = "GizmoAxis") -> RID:
	"""Create an axis line entity"""
	var mesh := create_axis_line_mesh(length, axis)
	var entity := FlecsScene.create_raw_entity_with_name(name)
	
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)

	var shape := mesh.create_convex_shape()
	
	var body_comp := Components.PhysicsBody.new(shape, scenario, transform)
	body_comp.set_body_type(PhysicsServer3D.BODY_MODE_STATIC)
	body_comp.set_collision_layer(Components.PhysicsMasks.GizmoLayer)
	body_comp.set_collision_mask(Components.PhysicsMasks.GizmoLayer)
	
	FlecsScene.entity_add_component_instance(entity, Components.PhysicsBody.get_type_name(), body_comp)
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	
	return entity


static func create_circle_entity(scenario: World3D, radius: float, segments: int, normal: Vector3, material: Material, transform: Transform3D = Transform3D.IDENTITY, name: String = "GizmoCircle") -> RID:
	"""Create a circle entity for rotation gizmos"""
	var mesh := create_circle_mesh(radius, segments, normal)
	var entity := FlecsScene.create_raw_entity_with_name(name)
	
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)
	
	var shape := mesh.create_convex_shape()
	
	var body_comp := Components.PhysicsBody.new(shape, scenario, transform)
	body_comp.set_body_type(PhysicsServer3D.BODY_MODE_STATIC)
	body_comp.set_collision_layer(Components.PhysicsMasks.GizmoLayer)
	body_comp.set_collision_mask(Components.PhysicsMasks.GizmoLayer)
	
	FlecsScene.entity_add_component_instance(entity, Components.PhysicsBody.get_type_name(), body_comp)
	
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	
	return entity


static func create_handle_entity(scenario: World3D, radius: float, material: Material, transform: Transform3D = Transform3D.IDENTITY, shape: String = "sphere", name: String = "GizmoHandle") -> RID:
	"""Create a handle entity (sphere or box)"""
	var mesh: Mesh
	if shape == "box":
		mesh = create_box_mesh(radius * 2.0)
	else:
		mesh = create_sphere_mesh(radius)
	
	var entity := FlecsScene.create_raw_entity_with_name(name)
	
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)
	var shape_physics := mesh.create_convex_shape()
	var body_comp := Components.PhysicsBody.new(shape_physics, scenario, transform)
	body_comp.set_body_type(PhysicsServer3D.BODY_MODE_STATIC)
	body_comp.set_collision_mask(Components.PhysicsMasks.GizmoLayer)
	body_comp.set_collision_layer(Components.PhysicsMasks.GizmoLayer)
	
	FlecsScene.entity_add_component_instance(entity, Components.PhysicsBody.get_type_name(), body_comp)
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	
	return entity


static func create_arrow_entity(scenario: World3D, material: Material, transform: Transform3D = Transform3D.IDENTITY, length: float = 1.0, name: String = "GizmoArrow") -> RID:
	"""Create an arrow entity pointing up (Y+)"""
	var mesh := create_arrow_mesh(length * 0.8, length * 0.2)
	var entity := FlecsScene.create_raw_entity_with_tag(name)
	
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)
	
	var shape := mesh.create_convex_shape()
	
	var body_comp := Components.PhysicsBody.new(shape, scenario, transform)
	body_comp.set_body_type(PhysicsServer3D.BODY_MODE_STATIC)
	body_comp.set_collision_layer(Components.PhysicsMasks.GizmoLayer)
	body_comp.set_collision_mask(Components.PhysicsMasks.GizmoLayer)
	
	FlecsScene.entity_add_component_instance(entity, Components.PhysicsBody.get_type_name(), body_comp)
	
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	return entity


static func create_cone_entity(scenario: World3D, radius: float, height: float, material: Material, transform: Transform3D = Transform3D.IDENTITY, name: String = "GizmoCone") -> RID:
	"""Create a cone entity"""
	var mesh := create_cone_mesh(radius, height)
	var entity := FlecsScene.create_raw_entity_with_name(name)
	
	mesh.surface_set_material(0, material)
	var mesh_comp := Components.MeshComponent.new(mesh, scenario)
	
	FlecsScene.entity_add_component_instance(entity, "Transform3D", transform)
	FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
	
	return entity


static func create_translation_gizmo_parts(world_pos: Vector3, scenario: World3D, length: float = 1.0) -> Dictionary:
	"""Create all parts for a translation gizmo and parent them. Returns entity RIDs."""
	var query := Query.new()
	query.with_and_register(Components.PhysicsBody.get_type_name())
	query.with_relation(Relationships.child_of(), Globals.GIZMO_ID)
	if (Globals.gizmo_entities_by_renderable_rid != null and !Globals.gizmo_entities_by_renderable_rid.is_empty()):

		query.each(func _iter(_child: RID, components: Array):
			var body : Components.PhysicsBody = components[0]
			var xform : Transform3D = body.get_transform()
			xform.origin = world_pos
			pass
		)
		return Globals.gizmo_entities_by_renderable_rid
	
	var parts := {}
	
	# Materials
	var mat_x := create_gizmo_material(Color(0.96, 0.20, 0.32))
	var mat_y := create_gizmo_material(Color(0.53, 0.84, 0.01))
	var mat_z := create_gizmo_material(Color(0.16, 0.55, 0.96))
	
	# X Axis (Red)
	var x_arrow := create_arrow_entity(scenario, mat_x, Transform3D(Basis.from_euler(Vector3(0, 0, -PI/2)), Vector3.ZERO), length, "TranslateX_Arrow")
	var x_handle_info := GizmoPartInfo.new(x_arrow, AxisType.AXIS_X)
	FlecsScene.entity_add_child(Globals.GIZMO_ID, x_arrow)
	
	var x_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(x_arrow, Components.PhysicsBody.get_type_name())
	parts[x_body.body_id] = x_handle_info
	
	# Y Axis (Green)
	var y_arrow := create_arrow_entity(scenario, mat_y, Transform3D.IDENTITY, length, "TranslateY_Arrow")
	FlecsScene.entity_add_child(Globals.GIZMO_ID, y_arrow)
	var y_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(y_arrow, Components.PhysicsBody.get_type_name())
	var y_handle_info := GizmoPartInfo.new(y_arrow, AxisType.AXIS_Y)
	parts[y_body.body_id] = y_handle_info
	
	# Z Axis (Blue)
	var z_arrow := create_arrow_entity(scenario, mat_z, Transform3D(Basis.from_euler(Vector3(PI/2, 0, 0)), Vector3.ZERO), length, "TranslateZ_Arrow")
	FlecsScene.entity_add_child(Globals.GIZMO_ID, z_arrow)
	var z_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(z_arrow, Components.PhysicsBody.get_type_name())
	var z_handle_info := GizmoPartInfo.new(z_arrow, AxisType.AXIS_Z)
	parts[z_body.body_id] = z_handle_info
	
	
	query.each(func _iter(_child: RID, components: Array):
		var body : Components.PhysicsBody = components[0]
		var xform : Transform3D = body.get_transform()
		xform.origin = world_pos
		pass
	)
	
	return parts


static func create_rotation_gizmo_parts(scenario: World3D, parent_entity: RID, radius: float = 1.0, segments: int = 32) -> Dictionary:
	"""Create all parts for a rotation gizmo. Returns entity RIDs."""
	var parts := {}
	
	# Materials
	var mat_x := create_gizmo_material(Color(0.96, 0.20, 0.32))
	var mat_y := create_gizmo_material(Color(0.53, 0.84, 0.01))
	var mat_z := create_gizmo_material(Color(0.16, 0.55, 0.96))
	
	# X Circle (YZ plane)
	var x_circle := create_circle_entity(scenario, radius, segments, Vector3.RIGHT, mat_x, Transform3D.IDENTITY, "RotateX_Circle")
	FlecsScene.entity_add_child(parent_entity, x_circle)
	parts["x_circle"] = x_circle
	
	# Y Circle (XZ plane)
	var y_circle := create_circle_entity(scenario, radius, segments, Vector3.UP, mat_y, Transform3D.IDENTITY, "RotateY_Circle")
	FlecsScene.entity_add_child(parent_entity, y_circle)
	parts["y_circle"] = y_circle
	
	# Z Circle (XY plane)
	var z_circle := create_circle_entity(scenario, radius, segments, Vector3.BACK, mat_z, Transform3D.IDENTITY, "RotateZ_Circle")
	FlecsScene.entity_add_child(parent_entity, z_circle)
	parts["z_circle"] = z_circle
	
	return parts


static func create_scale_gizmo_parts(scenario: World3D, parent_entity: RID, length: float = 1.0) -> Dictionary:
	"""Create all parts for a scale gizmo. Returns entity RIDs."""
	var parts := {}
	
	# Materials
	var mat_x := create_gizmo_material(Color(0.96, 0.20, 0.32))
	var mat_y := create_gizmo_material(Color(0.53, 0.84, 0.01))
	var mat_z := create_gizmo_material(Color(0.16, 0.55, 0.96))
	var mat_center := create_gizmo_material(Color(1, 1, 1, 0.8))
	
	# X Axis
	var x_line := create_axis_entity(scenario, length * 0.9, Vector3.RIGHT, mat_x, Transform3D.IDENTITY, "ScaleX_Line")
	var x_handle := create_handle_entity(scenario, 0.08, mat_x, Transform3D(Basis.IDENTITY, Vector3(length, 0, 0)), "box", "ScaleX_Handle")
	FlecsScene.entity_add_child(parent_entity, x_line)
	FlecsScene.entity_add_child(parent_entity, x_handle)
	parts["x_line"] = x_line
	parts["x_handle"] = x_handle
	
	# Y Axis
	var y_line := create_axis_entity(scenario, length * 0.9, Vector3.UP, mat_y, Transform3D.IDENTITY, "ScaleY_Line")
	var y_handle := create_handle_entity(scenario, 0.08, mat_y, Transform3D(Basis.IDENTITY, Vector3(0, length, 0)), "box", "ScaleY_Handle")
	FlecsScene.entity_add_child(parent_entity, y_line)
	FlecsScene.entity_add_child(parent_entity, y_handle)
	parts["y_line"] = y_line
	parts["y_handle"] = y_handle
	
	# Z Axis
	var z_line := create_axis_entity(scenario, length * 0.9, Vector3.BACK, mat_z, Transform3D.IDENTITY, "ScaleZ_Line")
	var z_handle := create_handle_entity(scenario, 0.08, mat_z, Transform3D(Basis.IDENTITY, Vector3(0, 0, length)), "box", "ScaleZ_Handle")
	FlecsScene.entity_add_child(parent_entity, z_line)
	FlecsScene.entity_add_child(parent_entity, z_handle)
	parts["z_line"] = z_line
	parts["z_handle"] = z_handle
	
	# Center handle for uniform scaling
	var center_handle := create_handle_entity(scenario, 0.12, mat_center, Transform3D.IDENTITY, "sphere", "ScaleCenter_Handle")
	FlecsScene.entity_add_child(parent_entity, center_handle)
	parts["center_handle"] = center_handle
	
	return parts
