class_name InteractionSystem extends Node

var interactors_query := Query.new()
var interactables_query := Query.new()

func _ready() -> void:
	self.interactors_query.with_and_register(Components.Interactor.get_type_name())
	self.interactors_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.interactors_query.with_and_register(Components.Controller.get_type_name())
	self.interactables_query.with_and_register(Components.Interactable.get_type_name())
	self.interactables_query.with_and_register(Components.PhysicsBody.get_type_name())

func _get_interaction_from_input(event : InputEvent, controller : Components.Controller) -> Components.Interaction:
	#print("_get_interaction_from_input called")
	#print("  action: ", event.as_text())
	
	if event.is_action_pressed(controller.use_action) and !event.is_echo():
		return Components.Interaction.Use
	
	return Components.Interaction.None

func _handle_input(event : InputEvent) -> void:
	self.interactors_query.each(func cb_interactors(interactor_id : RID, interactor_comps : Array):
		var interactor_comp : Components.Interactor = interactor_comps[0]
		var interactor_phybod_comp : Components.PhysicsBody = interactor_comps[1]
		var interactor_controller_comp : Components.Controller = interactor_comps[2]
		
		var interaction := self._get_interaction_from_input(event, interactor_controller_comp)
		
		# interaction must be valid, Components.Interaction.None interaction is returned if input cannot 
		# be mapped to any of the current interactor controlls
		if interaction == Components.Interaction.None:
			return
		
		var closest_interactable = {
			"distance_to_interactor": INF,
			"closest_interactable_id": RID(),
			"closest_interactable_comp": null
		}
		
		self.interactables_query.each(func cb_interactables(interactable_id : RID, interactable_comps: Array):
			var interactable_comp : Components.Interactable = interactable_comps[0]
			var interactable_phybod_comp : Components.PhysicsBody = interactable_comps[1]
			
			# enabled / disabled interactable state
			if interactable_comp.enabled == false:
				return
			
			# interactor must be on interactable range to interact
			var distance_to_interactor = interactable_phybod_comp.get_transform().origin.distance_to(interactor_phybod_comp.get_transform().origin)
			
			if distance_to_interactor > interactable_comp.interaction_range:
				return
			
			# only consider the closest interactable to interactor
			if distance_to_interactor > closest_interactable["distance_to_interactor"]:
				return
			
			closest_interactable["distance_to_interactor"] = distance_to_interactor
			closest_interactable["closest_interactable_id"] = interactable_id
			closest_interactable["closest_interactable_comp"] = interactable_comp
			
			# TODO: (optional) ensure no more than 1 event with the same values exists
			# TODO: (optional) ensure no more than 1 event per interactable exist 
			# TODO: lock interaction -> reserve interactable interactions to specific interactor
			# TODO: handle on_enter / on_exit interactable area events
		)
		
		var closest_interactable_id : RID = closest_interactable["closest_interactable_id"]
		var closest_interactable_comp : Components.Interactable = closest_interactable["closest_interactable_comp"]
		
		# did any valid interaction took place at all, if not we are done
		if closest_interactable_comp == null:
			return
		
		# cooldown
		var now : int = Time.get_ticks_msec()
		
		if now - closest_interactable_comp.last_interaction < closest_interactable_comp.cooldown:
			return
		
		closest_interactable_comp.last_interaction = now
		
		# add interaction event to queue
		# is the specific interactable system responsability to handle such event and delete it from the queue
		InteractionEventQueue.register_event(closest_interactable_id, interactor_id, interaction)
	)
	
func _input(event : InputEvent) -> void:
	self._handle_input(event)

func _process(delta: float) -> void:
	pass
