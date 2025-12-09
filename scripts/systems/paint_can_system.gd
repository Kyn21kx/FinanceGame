class_name PaintCanSystem extends Node

var cans_query := Query.new()

func _ready() -> void:
	self.cans_query.with_and_register(Components.PaintCan.get_type_name())
	self.cans_query.with_and_register(Components.MeshComponent.get_type_name())
	self.cans_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.cans_query.with_and_register(Components.Interactable.get_type_name())

func _input(input_event : InputEvent) -> void:
	InteractionEventQueue.process_interactable_with_tag_events(Components.PaintCan.get_type_name(), func (event : Components.InteractionEvent):
		if event.interaction == Components.Interaction.Use:
			var interactable_can_comp : Components.PaintCan = FlecsScene.get_component_from_entity(event.interactable, Components.PaintCan.get_type_name())
			var interactable_phybod_comp : Components.PhysicsBody = FlecsScene.get_component_from_entity(event.interactable, Components.PhysicsBody.get_type_name())
			var interactable_mesh_comp : Components.MeshComponent = FlecsScene.get_component_from_entity(event.interactable, Components.MeshComponent.get_type_name())
			var interactor_mesh_comp : Components.MeshComponent = FlecsScene.get_component_from_entity(event.interactor, Components.MeshComponent.get_type_name()) 
			
			var material = interactor_mesh_comp.mesh.surface_get_material(0)
			material.albedo_color = interactable_can_comp.color
			interactor_mesh_comp.mesh.surface_set_material(0, material)
			
			FlecsScene.destroy_raw_entity(event.interactable, func destructor():
				PhysicsServer3D.body_remove_shape(interactable_phybod_comp.body_id, 0)
				RenderingServer.free_rid(interactable_mesh_comp.instance)
			)
	)

func _process(delta: float) -> void:
	self.cans_query.each(func cb_cans(entity_id : RID, comps: Array):
		var can_comp : Components.PaintCan = comps[0]
		var mesh_comp : Components.MeshComponent = comps[1]
		var phybod_comp : Components.PhysicsBody = comps[2]
		var interactable_comp : Components.Interactable = comps[3]
		
		# sync mesh color with can_comp.color 
		var material = mesh_comp.mesh.surface_get_material(0)
		
		if material.albedo_color != can_comp.color: 
			material.albedo_color = can_comp.color
			mesh_comp.mesh.surface_set_material(0, material)
		
		# DebugDraw3D.draw_sphere(phybod_comp.get_transform().origin, interactable_comp.interaction_range, can_comp.color)
	)
