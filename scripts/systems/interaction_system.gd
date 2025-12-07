class_name InteractionSystem

var interactors_query := Query.new()
var interactables_query := Query.new()

func _ready() -> void:
	self.interactors_query.with_and_register(Components.Interactor.get_type_name())
	self.interactors_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.interactors_query.with_and_register(Components.Controller.get_type_name())
	self.interactables_query.with_and_register(Components.Interactable.get_type_name())
	self.interactables_query.with_and_register(Components.PhysicsBody.get_type_name())

func _get_interaction_from_input(event : InputEvent, controller : Components.Controller) -> Components.Interaction:
	if event.action == controller.use_action:
		return Components.Interaction.Use
	
	return Components.Interaction.None

func _input(event : InputEvent) -> void:
	self.interactables_query.each(func cb_interactables(interactable_id : RID, interactable_comps: Array):
		var interactable_comp = interactable_comps[0]
		var interactable_phybod_comp : Components.PhysicsBody = interactable_comps[1]
		
		self.interactors_query.each(func cb_interactors(interactor_id : RID, interactor_comps : Array):
			var interactor_comp : Components.Interactor = interactor_comps[0]
			var interactor_phybod_comp : Components.PhysicsBody = interactor_comps[1]
			var interactor_controller_comp : Components.Controller = interactor_comps[2]
			
			# interactor must be on interactable range to interact
			if interactable_phybod_comp.get_transform().origin.distance_to(interactor_phybod_comp.get_transform().origin) > interactable_comp.interaction_range:
				return
			
			var interaction := self._get_interaction_from_input(event, interactor_controller_comp)
			
			# interaction must be valid, Components.Interaction.None interaction is returned if input cannot 
			# be mapped to any of the current interactor controlls
			if interaction == Components.Interaction.None:
				return
			
			# add event to queue, is the specific interactable system responsability to handle 
			# such event and delete it from the queue
			InteractionEventQueue.register_event(interactable_id, interactor_id, interaction)
			
			# TODO: (optional) ensure no more than 1 event with the same values exists
			# TODO: (optional) ensure no more than 1 event per interactable exist 
			# TODO: interaction cooldown
			# TODO: lock interaction -> enabled / disable interactable state
			# TODO: lock interaction -> reserve interactable interaction to specific interactor
		)
	)
