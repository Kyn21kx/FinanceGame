class_name InteractionEventQueue extends Node

static var _event_query : Query

func _ready() -> void:
	InteractionEventQueue._event_query = Query.new()
	InteractionEventQueue._event_query.with_and_register(Components.InteractionEvent.get_type_name())

static func process_interactable_events(interactable_id : RID, on_event_callback: Callable, event_handled : bool = true) -> void:
	# expected callback: on_event(event : Component.InteractionEvent)
	if InteractionEventQueue._event_query == null:
		return
	
	InteractionEventQueue._event_query.each(func process_events(event_id: RID, components: Array):
		var event : Components.InteractionEvent = components[0]
		
		if event.interactable != interactable_id:
			return
		
		on_event_callback.call(event)
		
		if event_handled:
			InteractionEventQueue.event_handled(event_id)
	)

static func process_interactable_with_tag_events(tag : StringName, on_event_callback: Callable, event_handled : bool = true) -> void:
	# expected callback: on_event(event : Component.InteractionEvent)
	if InteractionEventQueue._event_query == null:
		return
	
	InteractionEventQueue._event_query.each(func process_events(event_id: RID, components: Array):
		var event : Components.InteractionEvent = components[0]
		
		if FlecsScene.entity_has_component(event.interactable, tag) == false:
			return
		
		on_event_callback.call(event)
		
		if event_handled:
			InteractionEventQueue.event_handled(event_id)
	)

static func event_handled(event_id : RID) -> void:
	FlecsScene.destroy_raw_entity(event_id, func destructor():
		pass
	)

static func register_event(interactable_id : RID, interactor_id : RID, interaction : Components.Interaction) -> void:
	# admitedley we could just store them on a regular array, but...
	
	# print("register_event(interactable_id: %s, interactor_id: %s, interaction: %s)" % [interactable_id, interactor_id, interaction])
	
	var interaction_event := FlecsScene.create_raw_entity()
	var interaction_event_comp := Components.InteractionEvent.new()
	
	interaction_event_comp.interactable = interactable_id
	interaction_event_comp.interactor = interactor_id
	interaction_event_comp.interaction = interaction
	
	FlecsScene.entity_add_component_instance(interaction_event, Components.InteractionEvent.get_type_name(), interaction_event_comp)
