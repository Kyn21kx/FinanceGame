extends Node
class_name RenderingSystem

var renderable_bodies_query := Query.new()
var renderable_non_physics_query := Query.new()

func _ready() -> void:
	# The query for physics objects
	self.renderable_bodies_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.renderable_bodies_query.with_and_register(Components.MeshComponent.get_type_name())
	self.renderable_bodies_query.cache_mode(Query.Cached)

	# The query for normal transform bound objects
	self.renderable_non_physics_query.with_and_register("Transform3D")
	self.renderable_non_physics_query.with_and_register(Components.MeshComponent.get_type_name())
	self.renderable_non_physics_query.cache_mode(Query.Cached)
	

func _physics_process(_delta: float) -> void:
	self.renderable_bodies_query.each(func render_physic_meshes(components: Array):
		# Body, Mesh
		var body : Components.PhysicsBody = components[0]
		var mesh : Components.MeshComponent = components[1]
		var xform : Transform3D = body.get_transform()
		RenderingServer.instance_set_transform(mesh.instance, xform)
		pass
	)
	pass

func _process(_delta: float) -> void:
	self.renderable_non_physics_query.each(func render_non_physic_meshes(components: Array):
		# Xform, Mesh
		var xform : Transform3D = components[0]
		var mesh: Components.MeshComponent = components[1]
		
		RenderingServer.instance_set_transform(mesh.instance, xform)
	)
