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
		
		while j > -1 and targets[j][0].priority > key[0].priority:
			targets[j + 1] = targets[j]
			j = j - 1
		
		targets[j + 1] = key
	
	return targets

func are_all_targets_visible(target_comps, camera : Camera3D) -> bool:
	for target_components in target_comps:
		var target_camera_follow : Components.CameraFollow = target_components[0]
		var target_body : Components.PhysicsBody = target_components[1]        
		
		if camera.is_position_in_frustum(target_body.get_transform().origin) == false:
			return false
			
		if camera.is_position_behind(target_body.get_transform().origin):
			return false
	
	return true

func _physics_process(_delta : float) -> void:
	self.cameras_query.each(func process_cameras(camera_entity: RID, camera_components: Array):
		var camera : Components.Camera = camera_components[0]
		
		var sorted_targets = get_targets_sorted_by_priority()
		
		if sorted_targets.size() == 0:
			return
		
		var primary_objective = sorted_targets[0]
		var primary_objective_body : Components.PhysicsBody = primary_objective[1]
		
		# point to the primary objective, the bag
		# var main_target_pos = primary_objective_body.get_transform().origin
		
		# camera.camera_ref.look_at(main_target_pos)
		
		# adjust zoom to try and show as many secondary targets as possible
		# var zoom_in_direction = (main_target_pos - camera.camera_ref.position) / 20
		
		var zoom_in_direction = camera.camera_ref.basis.z * -1
		
		# if all are visible, then zoom in until this is no longer the case
		while are_all_targets_visible(sorted_targets, camera.camera_ref):
			camera.camera_ref.position = camera.camera_ref.position + (zoom_in_direction * _delta)
		
		# then, make all of them visible. TODO: add max zoom out cap
		while are_all_targets_visible(sorted_targets, camera.camera_ref) == false:
			camera.camera_ref.position = camera.camera_ref.position + (zoom_in_direction * -1 * _delta)
	)
