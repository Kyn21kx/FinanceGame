class_name ModelECSCreator


const ARROW_LENGTH = 1.0
const ARROW_HEAD_SIZE = 0.2
const ARROW_BODY_RADIUS = 0.05
const ARROW_HEAD_RADIUS = 0.1

const COLOR_X = Color(1, 0, 0, 1)
const COLOR_Y = Color(0, 1, 0, 1)
const COLOR_Z = Color(0, 0, 1, 1)


static func create_line_mesh(points: PackedVector3Array) -> ArrayMesh:
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
	var points := PackedVector3Array([Vector3.ZERO, axis * length])
	return create_line_mesh(points)

static func create_model_entity(instance: Node, scenario: World3D) -> RID:
	var parent_entity : RID = FlecsScene.create_raw_entity_with_name(instance.name)
	var xform := Transform3D.IDENTITY if instance is not Node3D else (instance as Node3D).transform
	FlecsScene.entity_add_component_instance(parent_entity, "Transform3D", xform)
	if (instance is MeshInstance3D):
		var mesh_comp := Components.MeshComponent.new(instance.mesh, scenario)
		FlecsScene.entity_add_component_instance(parent_entity, Components.MeshComponent.get_type_name(), mesh_comp)

	# Go through the hierarchy and find mesh instances
	for child_node in instance.get_children():
		var child_mesh := child_node as MeshInstance3D
		if child_mesh == null:
			create_model_entity_from_node(child_node, scenario, parent_entity)
			continue

		# Create the mesh component here
		var child_entity: RID = FlecsScene.create_raw_entity_with_name(child_mesh.name)
		var mesh_comp := Components.MeshComponent.new(child_mesh.mesh, scenario)
		FlecsScene.entity_add_component_instance(child_entity, "Transform3D", child_mesh.transform)
		FlecsScene.entity_add_component_instance(child_entity, Components.MeshComponent.get_type_name(), mesh_comp)
		FlecsScene.entity_add_child(parent_entity, child_entity)
		create_model_entity_from_node(child_mesh, scenario, child_entity)

	return parent_entity


static func create_model_entity_from_node(instance: Node, scenario: World3D, parent: RID) -> RID:
	# Go through the hierarchy and find mesh instances
	for child_node in instance.get_children():
		var child_mesh := child_node as MeshInstance3D
		if child_mesh == null:
			create_model_entity_from_node(child_node, scenario, parent)
			continue
		# Create the mesh component here
		var entity : RID = FlecsScene.create_raw_entity_with_name(child_mesh.name)
		var mesh_comp := Components.MeshComponent.new(child_mesh.mesh, scenario)
		FlecsScene.entity_add_component_instance(entity, Components.MeshComponent.get_type_name(), mesh_comp)
		FlecsScene.entity_add_component_instance(entity, "Transform3D", child_mesh.transform)
		FlecsScene.entity_add_child(parent, entity)
		create_model_entity_from_node(child_mesh, scenario, entity)

	return rid_from_int64(0)
