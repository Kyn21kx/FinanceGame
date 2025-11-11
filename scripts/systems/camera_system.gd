extends Node
class_name CameraSystem

var cameras_query := Query.new()
var targets_query := Query.new() 

func _ready() -> void:
	self.cameras_query.with_and_register(Components.Camera.get_type_name())

	self.targets_query.with_and_register(Components.CameraTarget.get_type_name())
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

func is_target_visible(target_comps : Array, camera : Camera3D, padd_from_origin : float) -> bool:
	var target_camera_follow : Components.CameraTarget = target_comps[0]
	var target_body : Components.PhysicsBody = target_comps[1]        
	
	var directions = [
		Vector3(0, 0, 0), 
		Vector3(-1, 0, 0),
		Vector3(1, 0, 0),
		Vector3(0, 1, 0),
		Vector3(0, -1, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	
	for d in directions:
		var position = target_body.get_transform().origin + (d * padd_from_origin)
		
		if camera.is_position_in_frustum(position) == false or camera.is_position_behind(position):
			return false
	
	return true

func are_all_targets_visible(targets_comps : Array, camera : Camera3D, padd_from_origin : float) -> bool:
	for tc in targets_comps:
		if is_target_visible(tc, camera, padd_from_origin) == false:
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
		
		# if this flag is set, look at primary objective
		if camera.do_look_at_primary_objective:
			#camera.camera_ref.look_at(primary_objective_body.get_transform().origin)
			camera.camera_ref.look_at_from_position(camera.camera_ref.position, primary_objective_body.get_transform().origin)
		
		# adjust zoom to try and show as many targets as possible
		
		var zoom = camera.camera_ref.position.distance_to(camera.pivot)
		var direction = camera.camera_ref.position.direction_to(camera.pivot)
		var is_after_pivot = (direction.x + direction.y + direction.z) > 0

		# if all are visible, then zoom in until this is no longer the case
		while are_all_targets_visible(sorted_targets, camera.camera_ref, camera.target_padding):
			if (zoom > abs(camera.max_zoom_in) and is_after_pivot):
				break
			
			camera.camera_ref.position = camera.camera_ref.position + (camera.zoom_direction * _delta * camera.zoom_in_speed)
		
		# then, make all of them visible. TODO: add max zoom out cap
		while are_all_targets_visible(sorted_targets, camera.camera_ref, camera.target_padding) == false:
			if (zoom > abs(camera.max_zoom_out) and is_after_pivot == false):
				break
			
			camera.camera_ref.position = camera.camera_ref.position + (camera.zoom_direction * -1 * _delta * camera.zoom_out_seed)
	)
