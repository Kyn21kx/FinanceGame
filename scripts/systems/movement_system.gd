extends Node3D
class_name MovementSystem

var players_query := Query.new()

@export
var player_mat: StandardMaterial3D
var mesh := CylinderMesh.new()
var shape := CylinderShape3D.new()

func _ready() -> void:
	var test_entity : RID = FlecsScene.create_raw_entity_with_name("Player")

	var body_comp_instance := Components.PhysicsBody.new(shape, self.get_world_3d())
	# Lock the rigibody's rotation
	body_comp_instance.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_X)
	body_comp_instance.lock_axis(PhysicsServer3D.BODY_AXIS_ANGULAR_Z)
	FlecsScene.entity_add_component_instance(test_entity, Components.PhysicsBody.get_type_name(), body_comp_instance)

	self.mesh.material = self.player_mat
	var mesh_comp_instance := Components.MeshComponent.new(self.mesh, self.get_world_3d())
	FlecsScene.entity_add_component_instance(test_entity, Components.MeshComponent.get_type_name(), mesh_comp_instance)

	var movement_comp_instance := Components.Movement.new()
	movement_comp_instance.speed = 15
	movement_comp_instance.jump_force = 5
	FlecsScene.entity_add_component_instance(test_entity, Components.Movement.get_type_name(), movement_comp_instance)

	self.players_query.with_and_register(Components.Movement.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	pass

func _physics_process(_delta: float) -> void:
	# TODO: Process this by controller component
	var input := Vector3.ZERO
	var impulse := Vector3.ZERO
	if (Input.is_key_pressed(KEY_W)):
		input += Vector3.FORWARD
	if (Input.is_key_pressed(KEY_S)):
		input -= Vector3.FORWARD
	if (Input.is_key_pressed(KEY_A)):
		input -= Vector3.RIGHT
	if (Input.is_key_pressed(KEY_D)):
		input += Vector3.RIGHT
	if (Input.is_key_pressed(KEY_SPACE)):
		impulse = Vector3.UP

	self.players_query.each(func _move_bodies(components: Array):
		var movement: Components.Movement = components[0]
		var body: Components.PhysicsBody = components[1]
		movement.direction = input.normalized()
		body.apply_force(movement.direction * movement.speed)
		body.apply_impulse(impulse * movement.jump_force)
		pass
	)
	pass
