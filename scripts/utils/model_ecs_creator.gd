class_name ModelECSCreator


static func create_model_entity(prefab: PackedScene, scenario: World3D) -> RID:
	var instance : Node = prefab.instantiate()

	var parent_entity : RID = FlecsScene.create_raw_entity_with_name(instance.name)
	if (instance is MeshInstance3D):
		var mesh_comp := Components.MeshComponent.new(instance.mesh, scenario)
		FlecsScene.entity_add_component_instance(parent_entity, "Transform3D", instance.transform)
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

	instance.queue_free()
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
