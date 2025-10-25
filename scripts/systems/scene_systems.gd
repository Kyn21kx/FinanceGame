@tool
extends Node
class_name SceneSystems

var renderable_bodies_query := Query.new()
var renderable_non_physics_query := Query.new()
var rope_query := Query.new()
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
	var ray_end := ray_origin + ray_normal * length

	var space := self.get_world3d_consistent().direct_space_state
	if (space == null):
		return
	var query := PhysicsRayQueryParameters3D.new()

	query.from = ray_origin
	query.to = ray_end
	query.collide_with_areas = true
	query.collision_mask = Components.PhysicsMasks.GizmoLayer

	var result = space.intersect_ray(query)
	if (self.entities_by_renderable_rid.is_empty() || result == null || result.is_empty()):
		return

	var entity = self.entities_by_renderable_rid.get(result.rid)

	assert(entity != null, "Entities by renderable id dictionary ("+ str(self.entities_by_renderable_rid) +") does not contain collidable instance " + str(result.rid))

	print(entity)


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

func _physics_process(_delta: float) -> void:
	self.rope_query.each(rope_joint_system)
	self.renderable_bodies_query.each(render_physic_meshes)
	# TODO: Check if editor mode I guess
	self.gizmo_handle_selection_system()


func _process(_delta: float) -> void:
	self.renderable_non_physics_query.each(render_non_physic_meshes)
