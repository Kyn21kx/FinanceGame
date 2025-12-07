class_name InteractionEventQueue

static func event_handled(event_id : RID) -> void:
	FlecsScene.destroy_raw_entity(event_id, func destructor():
		pass
	)

static func register_event(interactable_id : RID, interactor_id : RID, interaction : Components.Interaction) -> void:
	var interaction_event := FlecsScene.create_raw_entity()
	var interaction_event_comp := Components.InteractionEvent.new()
	
	interaction_event_comp.interactable = interactable_id
	interaction_event_comp.interactor = interactor_id
	interaction_event_comp.interaction = interaction
	
	FlecsScene.entity_add_component_instance(interaction_event, Components.InteractionEvent.get_type_name(), interaction_event_comp)
