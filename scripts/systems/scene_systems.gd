@tool
extends Node
class_name SceneSystems

var renderable_bodies_query := Query.new()
var renderable_non_physics_query := Query.new()
var rope_query := Query.new()
var manipulated_query_xforms := Query.new()
var manipulated_query_bodies := Query.new()
var children_xforms := Query.new()

var editor_ray_query := PhysicsRayQueryParameters3D.new()
var mouse_last_position: Vector3
var gizmo_base_position: Vector3
var gizmo_move_direction: Vector3 = Vector3.ZERO
var GIZMO_SPAWN : RID

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

	self.children_xforms.with("Transform3D")
	self.children_xforms.with_relation(Relationships.child_of(), Globals.any())

	# Gizmo manipulating relationship
	Relationships.MANIPULATING = FlecsScene.create_raw_entity_with_tag("Manipulating")
	Globals.GIZMO_ID = FlecsScene.create_raw_entity_with_tag("Gizmo") # Does not matter which system runs first, the ID will be kept the same

	self.manipulated_query_xforms.with_relation(Relationships.child_of(), Globals.GIZMO_ID)
	self.manipulated_query_xforms.with("Transform3D")

	self.manipulated_query_bodies.with_relation(Relationships.child_of(), Globals.GIZMO_ID)
	self.manipulated_query_bodies.with(Components.PhysicsBody.get_type_name())

	GIZMO_SPAWN = FlecsScene.create_raw_entity_with_tag("GIZMO_SPAWNED")
	FlecsScene.add_event_observer_raw(GIZMO_SPAWN, Globals.GIZMO_ID,  self.on_gizmo_spawned)

func on_gizmo_spawned(_gizmo_id: RID, parts: Dictionary) -> void:

	assert(_gizmo_id == Globals.GIZMO_ID, "Mismatched with local variable: local: " + str(_gizmo_id) + "; global: " + str(Globals.GIZMO_ID))
	FlecsScene.entity_each_relation_target(Globals.GIZMO_ID, Relationships.MANIPULATING, func _iter(ent: RID):
		FlecsScene.entity_remove_relation(ent, Relationships.child_of(), Globals.GIZMO_ID)
		FlecsScene.entity_remove_relation(Globals.GIZMO_ID, Relationships.MANIPULATING, ent)
	)

	Globals.gizmo_entities_by_renderable_rid = parts

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
	if (Globals.gizmo_handle_info != null):
		if (!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)):
			Globals.gizmo_handle_info = null
			return

	var space := self.get_world3d_consistent().direct_space_state
	if (space == null):
		return

	var result = space.intersect_ray(self.editor_ray_query)
	if (!Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		|| Globals.gizmo_entities_by_renderable_rid.is_empty()
		|| result == null
		|| result.is_empty()
		|| Globals.gizmo_handle_info != null):
		return

	self.gizmo_base_position = result.position
	Globals.gizmo_handle_info = Globals.gizmo_entities_by_renderable_rid.get(result.rid)
	assert(Globals.gizmo_handle_info != null,
		"Entities by renderable id dictionary (" + str(Globals.gizmo_entities_by_renderable_rid) +
		") does not contain collidable instance " + str(result.rid))


func rope_joint_system(_entity: RID, components: Array):
	# If the distance is bigger than its threshold, apply tension
	var rope_joint : Components.RopeJoint = components[0]
	var first_body_xform := rope_joint.body_a.get_transform()
	var second_body_xform := rope_joint.body_b.get_transform()
	var distance_sqr : float = (second_body_xform.origin - first_body_xform.origin).length_squared()
	DebugDraw3D.draw_line(rope_joint.body_a.get_transform().origin, rope_joint.body_b.get_transform().origin, Color.PURPLE)

	if distance_sqr >= rope_joint.length * rope_joint.length:
		# Apply tension force
		var direction : Vector3 = (second_body_xform.origin - first_body_xform.origin).normalized()
		var excess_distance = sqrt(distance_sqr) - rope_joint.length
		var tension_force = direction * (excess_distance * rope_joint.strength)

		rope_joint.body_b.apply_force(-tension_force)
		# rope_joint.body_a.apply_force(tension_force)

		
		var relative_velocity := rope_joint.body_b.get_velocity() - rope_joint.body_a.get_velocity()
		var damping_force = -relative_velocity * rope_joint.damping * rope_joint.body_b.get_mass()

		rope_joint.body_b.apply_force(damping_force)
		# rope_joint.body_a.apply_force(-damping_force)



func render_physic_meshes(_entity: RID, components: Array):
	# Body, Mesh
	var body : Components.PhysicsBody = components[0]
	var mesh : Components.MeshComponent = components[1]
	var direct_state := PhysicsServer3D.body_get_direct_state(body.body_id)
	var xform : Transform3D = direct_state.transform

	# Update the component's transform for all other systems
	body.transform = xform
	# Then render
	RenderingServer.instance_set_transform(mesh.instance, xform)
	pass


func render_non_physic_meshes(entity: RID, components: Array):
	# Xform, Mesh
	var xform : Transform3D = components[0]
	var mesh: Components.MeshComponent = components[1]
	
	# Check if we have a parent, and if we do, transform our current xform by it
	var parent : RID = FlecsScene.entity_get_parent(entity)

	var world_matrix := Transform3D.IDENTITY
	if (parent.is_valid()):
		# TODO: Maybe make this a system?
		var parent_physics : Components.PhysicsBody = FlecsScene.get_component_from_entity(parent, Components.PhysicsBody.get_type_name())
		if (parent_physics == null):
			world_matrix = FlecsScene.get_component_from_entity(parent, "Transform3D")
		else:
			world_matrix = parent_physics.get_transform()

	# I meaaaan, if we only need the world xform, we can just set this here and render that
	xform = world_matrix * xform

	RenderingServer.instance_set_transform(mesh.instance, xform)

func gizmo_determine_direction() -> Vector3:

	if (Globals.gizmo_handle_info == null):
		return Vector3.ZERO
	# Drag
	# We need to "lock" the axis towards the basis direction, and lastly we modify it by the diff in sign
	var handle_body : Components.PhysicsBody = FlecsScene.get_component_from_entity(Globals.gizmo_handle_info.entity, Components.PhysicsBody.get_type_name())
	var _handle_xform : Transform3D = handle_body.get_transform()

	var diff := (self.editor_ray_query.to - self.mouse_last_position)
	if Globals.gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_X:
		return Vector3.RIGHT * signf(diff.x)
	elif Globals.gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_Y:
		return Vector3.UP * signf(diff.y)
	elif Globals.gizmo_handle_info.axis_type == GizmoUtils.AxisType.AXIS_Z:
		return Vector3.FORWARD * signf(diff.z)

	return Vector3.ZERO

func move_selected_entities(entity: RID, components: Array, move_delta: Vector3):
	if (components[0] is not Transform3D):
		var body: Components.PhysicsBody = components[0]
		var xform : Transform3D = body.get_transform()
		xform.origin += move_delta
		body.set_transform(xform)
		return

	var xform := components[0] as Transform3D
	xform.origin += move_delta
	FlecsScene.entity_add_component_instance(entity, "Transform3D", xform)

func gizmo_handle_move_system() -> void:
	if Globals.gizmo_handle_info == null:
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
		var move_delta: Vector3 = self.gizmo_move_direction * movement_amount
	
		# Apply the movement to all gizmo children and the manipulated objects
		self.manipulated_query_bodies.each(func _iter(entity: RID, components: Array):
			self.move_selected_entities(entity, components, move_delta)
		)

		self.manipulated_query_xforms.each(func _iter(entity: RID, components: Array):
			self.move_selected_entities(entity, components, move_delta)
		)
	
		# Update the base position for next frame
		self.gizmo_base_position += move_delta

func _physics_process(_delta: float) -> void:
	self.rope_query.each(rope_joint_system)
	self.renderable_bodies_query.each(render_physic_meshes)
	# TODO: Check if editor mode I guess
	self.gizmo_handle_selection_system()
	self.gizmo_handle_move_system()

# func move_children_xform(entity: RID, components: Array) -> void:
# 	var parent : RID = FlecsScene.entity_get_parent(entity)
# 	var parent_xform : Transform3D = FlecsScene.get_component_from_entity(parent, "Transform3D")
# 	if parent_xform == null:
# 		return
# 	var xform : Transform3D = components[0]
# 	parent_xform * xform
# 	pass


func _process(_delta: float) -> void:
	# self.children_xforms.each(move_children_xform())

	var cam = self.get_viewport_consistent().get_camera_3d()

	const MAX_GIZMO_SCALE := 20
	const MIN_GIZMO_SCALE := 1
	const MAX_DISTANCE := 200

	self.manipulated_query_bodies.each(func iter(_entity: RID, components: Array):
		var body : Components.PhysicsBody = components[0]
		var xform : Transform3D = body.get_transform()

		var distance : float = cam.global_position.distance_to(xform.origin)
		var scale : float = clampf(MAX_GIZMO_SCALE * (distance / MAX_DISTANCE), MIN_GIZMO_SCALE, MAX_GIZMO_SCALE)
		xform.basis = xform.basis.orthonormalized().scaled(Vector3.ONE * scale)
		body.set_transform(xform)
	)

	self.renderable_non_physics_query.each(render_non_physic_meshes)
	
