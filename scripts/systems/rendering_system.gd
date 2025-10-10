extends Node
class_name RenderingSystem

var renderable_bodies_query := Query.new()
var renderable_non_physics_query := Query.new()
var rope_query := Query.new()

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

func _physics_process(_delta: float) -> void:

	self.rope_query.each(rope_joint_system)

	self.renderable_bodies_query.each(func render_physic_meshes(_entity: RID, components: Array):
		# Body, Mesh
		var body : Components.PhysicsBody = components[0]
		var mesh : Components.MeshComponent = components[1]
		var xform : Transform3D = body.get_transform()
		RenderingServer.instance_set_transform(mesh.instance, xform)
		pass
	)
	pass

func _process(_delta: float) -> void:
	self.renderable_non_physics_query.each(func render_non_physic_meshes(_entity: RID, components: Array):
		# Xform, Mesh
		var xform : Transform3D = components[0]
		var mesh: Components.MeshComponent = components[1]
		
		RenderingServer.instance_set_transform(mesh.instance, xform)
	)
