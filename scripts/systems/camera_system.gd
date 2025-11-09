extends Node
class_name CameraSystem

var cameras_query := Query.new()
var targets_query := Query.new() 

func _ready() -> void:
	self.cameras_query.with_and_register(Components.Camera.get_type_name())

	self.targets_query.with_and_register(Components.CameraFollow.get_type_name())
	self.targets_query.with_and_register(Components.PhysicsBody.get_type_name())

func get_targets_sorted_by_priority() -> Array:
	# this uses insertion sort: not great but easy to implement
	
	var targets = []
	
	self.targets_query.each(func process_targets(target_entity: RID, target_components : Array):
		targets.append(target_components)
	)
	
	for i in range(len(targets)):
	
		var key =  targets[i]
		
		if i == 0:
			continue
		
		var j = i - 1
		
		while j > -1 and targets[j][0].Priority > key[0].Priority:
			targets[j + 1] = targets[j]
			j = j - 1
		
		targets[j + 1] = key
	
	return targets


func _physics_process(_delta : float) -> void:
	self.cameras_query.each(func process_cameras(camera_entity: RID, camera_components: Array):
		var camera : Components.Camera = camera_components[0]
		
		var sorted_targets = get_targets_sorted_by_priority()
		
		if sorted_targets.size() == 0:
			return
		
		var primary_objective = sorted_targets[0]
		var primary_objective_body : Components.PhysicsBody = primary_objective[1]
		
		# point to the primary objective, the bag
		var main_target_pos = primary_objective_body.get_transform().origin
		
		camera.camera_ref.look_at(main_target_pos)
		
		# TODO: adjust zoom to try and show as many secondary targets as possible
		var zoom_in_direction = camera.camera_ref.position - main_target_pos
		
		for target_components in sorted_targets.slice(1, sorted_targets.size() - 1):
			var target_camera_follow : Components.CameraFollow = target_components[0]
			var target_body : Components.PhysicsBody = target_components[1]        
	)
