class_name PaintCan extends RigidBody3D

var id : RID
var interactable_comp : Components.Interactable
var physics_body_comp : Components.PhysicsBody
var mesh_comp : Components.MeshComponent
var color : Color = Color.BLUE_VIOLET

func _ready() -> void:
	$MeshInstance3D.mesh.material.albedo_color = self.color
	
	# temporal, while the component editor gets built
	self.id = FlecsScene.create_raw_entity_with_name("PaintCan")
	self.interactable_comp = Components.Interactable.new()
	self.interactable_comp.interaction_range = 2
	self.interactable_comp.cooldown = 2
	self.interactable_comp.enabled = true
	self.physics_body_comp = Components.PhysicsBody.new($CollisionShape3D.shape)
	self.physics_body_comp.body_id = $".".get_rid()
	self.physics_body_comp.shape = $CollisionShape3D.shape.get_rid()
	self.physics_body_comp.shape_ref = $CollisionShape3D.shape
	self.mesh_comp = Components.MeshComponent.new($MeshInstance3D.mesh, self.get_viewport().world_3d)
	self.mesh_comp.mesh = $MeshInstance3D.mesh
	
	FlecsScene.entity_add_component_instance(self.id, Components.PhysicsBody.get_type_name(), self.physics_body_comp)
	FlecsScene.entity_add_component_instance(self.id, Components.Interactable.get_type_name(), self.interactable_comp)
	FlecsScene.entity_add_component_instance(self.id, Components.MeshComponent.get_type_name(), self.mesh_comp)

func _input(event: InputEvent) -> void:
	InteractionEventQueue.process_interactable_events(self.id, func(event : Components.InteractionEvent):
		var interactor_mesh : Components.MeshComponent = FlecsScene.get_component_from_entity(event.interactor, Components.MeshComponent.get_type_name())
		
		var material = interactor_mesh.mesh.surface_get_material(0)
		material.albedo_color = self.color
		interactor_mesh.mesh.surface_set_material(0, material)
		
		FlecsScene.destroy_raw_entity(self.id, func destructor():
			self.queue_free()
			PhysicsServer3D.body_remove_shape(self.physics_body_comp.body_id, 0)
			RenderingServer.free_rid(self.mesh_comp.instance)
		)
	)

func _process(delta: float) -> void:
	# DebugDraw3D.draw_sphere(self.physics_body_comp.get_transform().origin, self.interactable_comp.interaction_range, self.color)
	pass
