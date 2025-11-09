@tool
extends Node
class_name SceneSystems

var renderable_bodies_query := Query.new()
var renderable_non_physics_query := Query.new()
var rope_query := Query.new()
var gizmo_children_query := Query.new()

var editor_ray_query := PhysicsRayQueryParameters3D.new()
var mouse_last_position: Vector3
var gizmo_base_position: Vector3
var gizmo_move_direction: Vector3 = Vector3.ZERO
var gizmo_handle_info: GizmoUtils.GizmoPartInfo = null
var GIZMO_ID: RID
var GIZMO_SPAWN : RID
var entities_by_renderable_rid: Dictionary

# TODO: process this in parallel
func _ready() -> void:
	# The query for physics objects
	self.renderable_bodies_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.renderable_bodies_query.with_and_register(Components.MeshComponent.get_type_name())
	self.renderable_bodies_query.cache_mode(Query.Cached)

	self.rope_query.with_and_register(Components.RopeJoint.get_type_name())

	# The query for normal transform bound objects
	self.renderable_non_physics_query.with_and_register("Transform3D")
	self.renderable_non_physics_query.with_and_register(Components.MeshComponent.get_type_name())
	self.renderable_non_physics_query.cache_mode(Query.Cached)

	# Gizmo manipulating relationship
	Relationships.MANIPULATING = FlecsScene.create_raw_entity_with_tag("Manipulating")

	GIZMO_ID = FlecsScene.create_raw_entity_with_tag("Gizmo") # Does not matter which system runs first, the ID will be kept the same
	GIZMO_SPAWN = FlecsScene.create_raw_entity_with_tag("GIZMO_SPAWNED")
	FlecsScene.add_event_observer_raw(GIZMO_SPAWN, GIZMO_ID,  self.on_gizmo_spawned)
	self.gizmo_children_query.with(Components.PhysicsBody.get_type_name())
	self.gizmo_children_query.with_relation(rid_from_int64(FlecsScene.ChildOf), GIZMO_ID)

func on_gizmo_spawned(_entity: RID, parts: Dictionary) -> void:
	self.entities_by_renderable_rid = parts

func get_viewport_consistent() -> Viewport:
	if Engine.is_editor_hint():
		return EditorInterface.get_editor_viewport_3d()
	return self.get_viewport()

func get_world3d_consistent() -> World3D:
	return self.get_viewport_consistent().find_world_3d()

func gizmo_handle_selection_system():
	# Get the current raycast for the mouse position
	var viewport := self.get_viewport_consistent()
	var main_cam := viewport.get_camera_3d()
	assert(main_cam != null)

	var mouse_pos := viewport.get_mouse_position()
	var ray_origin := main_cam.project_ray_origin(mouse_pos)
	var ray_normal := main_cam.project_ray_normal(mouse_pos)

	const length := 1000
	self.mouse_last_position = self.editor_ray_query.to
	var ray_end := ray_origin + ray_normal * length

	self.editor_ray_query.from = ray_origin
	self.editor_ray_query.to = ray_end
	self.editor_ray_query.collide_with_areas = true
	self.editor_ray_query.collision_mask = Components.PhysicsMasks.GizmoLayer

	# Skip if we already know the handle, but we did all the ray stuff to update other functions
	if (self.gizmo_handle_info != null):
		if (!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			self.gizmo_handle_info = null
			return

	var space := self.get_world3d_consistent().direct_space_state
	if (space == null):
		return

	var result = space.intersect_ray(self.editor_ray_query)
	if (!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		|| self.entities_by_renderable_rid.is_empty()
		|| result == null
		|| result.is_empty()
		|| self.gizmo_handle_info != null):
		return

	self.gizmo_base_position = result.position
	self.gizmo_handle_info = self.entities_by_renderable_rid.get(result.rid)
	assert(gizmo_handle_info != null,
		"Entities by renderable id dictionary (" + str(self.entities_by_renderable_rid) +
		") does not contain collidable instance " + str(result.rid))


func rope_joint_system(_entity: RID, components: Array):
	# If the distance is bigger than its threshold, apply tension
	var rope_joint : Components.RopeJoint = components[0]
	var first_body_xform := rope_joint.body_a.get_transform()
	var second_body_xform := rope_joint.body_b.get_transform()
	var distance_sqr : float = (second_body_xform.origin - first_body_xform.origin).length_squared()

	if distance_sqr >= rope_joint.length * rope_joint.length:
		# Apply tension force
		var direction : Vector3 = (second_body_xform.origin - first_body_xform.origin).normalized()
		var excess_distance = sqrt(distance_sqr) - rope_joint.length
		var tension_force = direction * (excess_distance * rope_joint.strength)

		rope_joint.body_b.apply_force(-tension_force)
		rope_joint.body_a.apply_force(tension_force)

		
		var relative_velocity := rope_joint.body_b.get_velocity() - rope_joint.body_a.get_velocity()
		var damping_force = -relative_velocity * rope_joint.damping * rope_joint.body_b.get_mass()

		rope_joint.body_b.apply_force(damping_force)
		rope_joint.body_a.apply_force(-damping_force)



func render_physic_meshes(_entity: RID, components: Array):
	# Body, Mesh
	var body : Components.PhysicsBody = components[0]
	var mesh : Components.MeshComponent = components[1]
	var xform : Transform3D = body.get_transform()

	RenderingServer.instance_set_transform(mesh.instance, xform)
	pass


func render_non_physic_meshes(_entity: RID, components: Array):
	# Xform, Mesh
	var xform : Transform3D = components[0]
	var mesh: Components.MeshComponent = components[1]
	
	RenderingServer.instance_set_transform(mesh.instance, xform)

func gizmo_determine_direction() -> Vector3:

	if (self.gizmo_handle_info == null):
		return Vector3.ZERO
	# Drag
	# We need to "lock" the axis towards the basis direction, and lastly we modify it by the diff in sign
	var handle_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(self.gizmo_handle_info.entity, Components.PhysicsBody.get_type_name())
	var _handle_xform : Transform3D = handle_body.get_transform()

	var diff := (self.editor_ray_query.to - self.mouse_last_position)
	if gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_X:
		return Vector3.RIGHT * signf(diff.x)
	elif gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_Y:
		return Vector3.UP * signf(diff.y)
	elif gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_Z:
		return Vector3.FORWARD * signf(diff.z)

	return Vector3.ZERO


func gizmo_handle_move_system() -> void:
	if self.gizmo_handle_info == null:
		return

	var viewport := self.get_viewport_consistent()
	var cam := viewport.get_camera_3d()
	var mouse_pos := viewport.get_mouse_position()

	# Calculate the movement direction
	self.gizmo_move_direction = gizmo_determine_direction()

	# Create a plane perpendicular to the camera for mouse projection
	var camera_forward := -cam.global_transform.basis.z
	var movement_plane := Plane(camera_forward, self.gizmo_base_position)

	# Project current mouse position onto the movement plane
	var current_ray_origin := cam.project_ray_origin(mouse_pos)
	var current_ray_normal := cam.project_ray_normal(mouse_pos)
	var current_intersection = movement_plane.intersects_ray(current_ray_origin, current_ray_normal)

	if current_intersection:
		# Project the intersection point onto our movement axis
		var local_to_axis = current_intersection - self.gizmo_base_position
		var movement_amount = local_to_axis.dot(self.gizmo_move_direction)
	
		# Apply the movement to all gizmo children and the manipulated objects
		self.gizmo_children_query.each(func iter(_entity: RID, components: Array):
			var body : Components.PhysicsBody = components[0]
			var xform : Transform3D = body.get_transform()
		
			# Move along the determined axis
			xform.origin += self.gizmo_move_direction * movement_amount
			body.set_transform(xform)
		)
	
		# Also move any objects that are being manipulated
		# self.manipulate_selected_objects(self.gizmo_move_direction * movement_amount)
	
		# Update the base position for next frame
		self.gizmo_base_position += self.gizmo_move_direction * movement_amount

func _physics_process(_delta: float) -> void:
	self.rope_query.each(rope_joint_system)
	self.renderable_bodies_query.each(render_physic_meshes)
	# TODO: Check if editor mode I guess
	self.gizmo_handle_selection_system()
	self.gizmo_handle_move_system()



func _process(_delta: float) -> void:
	self.renderable_non_physics_query.each(render_non_physic_meshes)

	var cam = self.get_viewport_consistent().get_camera_3d()

	const MAX_GIZMO_SCALE := 10
	const MIN_GIZMO_SCALE := 1
	const MAX_DISTANCE := 200

	self.gizmo_children_query.each(func iter(_entity: RID, components: Array):
		var body : Components.PhysicsBody = components[0]
		var xform : Transform3D = body.get_transform()

		var distance : float = cam.global_position.distance_to(xform.origin)
		var scale : float = clampf(MAX_GIZMO_SCALE * (distance / MAX_DISTANCE), MIN_GIZMO_SCALE, MAX_GIZMO_SCALE)
		xform.basis = xform.basis.orthonormalized().scaled(Vector3.ONE * scale)
		body.set_transform(xform)
	)
	
