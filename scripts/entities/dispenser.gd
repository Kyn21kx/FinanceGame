class_name Dispenser extends StaticBody3D

@export var interaction_range : float = 20
@export var spawn_system : EntitySpawnSystem

var dispenser_id : RID 
var dispenser_comp : Components.DispenserComponent
var inventory_comp : Components.Inventory
var interactable_comp : Components.Interactable
var mesh_comp : Components.MeshComponent
var physics_body_comp : Components.PhysicsBody

func _ready() -> void:
	var temp_mesh = $MeshInstance3D
	var temp_collision = $CollisionShape3D
	
	# this is only temporary, while the component editor gets finished
	self.dispenser_id = FlecsScene.create_raw_entity_with_name("Dispenser")
	self.dispenser_comp = Components.DispenserComponent.new()
	self.inventory_comp = Components.Inventory.new()
	self.interactable_comp = Components.Interactable.new(interaction_range)
	self.mesh_comp = Components.MeshComponent.new(temp_mesh.mesh, self.get_viewport().world_3d)
	self.physics_body_comp = Components.PhysicsBody.new(temp_collision.shape) 
	
	self.physics_body_comp.get_transform().origin.z -= 10
	self.physics_body_comp.get_transform().origin.x -= 10
	self.physics_body_comp.set_body_type(0)
	
	FlecsScene.entity_add_component_instance(self.dispenser_id, Components.DispenserComponent.get_type_name(), self.dispenser_comp)
	FlecsScene.entity_add_component_instance(self.dispenser_id, Components.Inventory.get_type_name(), self.inventory_comp)
	FlecsScene.entity_add_component_instance(self.dispenser_id, Components.Interactable.get_type_name(), self.interactable_comp)
	FlecsScene.entity_add_component_instance(self.dispenser_id, Components.PhysicsBody.get_type_name(), self.physics_body_comp)
	FlecsScene.entity_add_component_instance(self.dispenser_id, Components.MeshComponent.get_type_name(), self.mesh_comp)
	
	# queue_free()
	temp_mesh.queue_free()
	temp_collision.queue_free()

func _input(input_event: InputEvent) -> void:
	InteractionEventQueue.process_interactable_events(self.dispenser_id, func(event : Components.InteractionEvent):
		if event.interaction == Components.Interaction.Use:
			print("procesing event, interaction: $s", event.interaction)
			var spawn_position = physics_body_comp.get_transform().origin
			spawn_position.y += 3
			spawn_position.z += 3
			spawn_system._make_coin_default_shape(spawn_position)
	)

func _process(delta: float) -> void:
	var color = Color(65, 105, 225)
	var size = Vector3(interaction_range * 2, interaction_range * 2, interaction_range * 2)
	var position = self.physics_body_comp.get_transform().origin
	position.x -= interaction_range
	position.y -= interaction_range
	position.z -= interaction_range
	
	DebugDraw3D.draw_box(position, Quaternion.IDENTITY, size, color)
