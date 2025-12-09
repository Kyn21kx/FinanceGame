class_name Dispenser extends StaticBody3D

@export var spawn_system : EntitySpawnSystem

var id : RID 
var inventory_comp : Components.Inventory
var interactable_comp : Components.Interactable
var mesh_comp : Components.MeshComponent
var physics_body_comp : Components.PhysicsBody

# @onready var paint_can_scene: PackedScene = preload("res://scenes/entities/paint_can.tscn")

func _ready() -> void:
	# this is only temporary, while the component editor gets finished
	self.id = FlecsScene.create_raw_entity_with_name("Dispenser")
	self.inventory_comp = Components.Inventory.new()
	self.interactable_comp = Components.Interactable.new(5, 2000)
	self.physics_body_comp = Components.PhysicsBody.new($CollisionShape3D.shape)
	self.physics_body_comp.set_body_id($".".get_rid())
	self.mesh_comp = Components.MeshComponent.new($MeshInstance3D.mesh, self.get_viewport().world_3d)
	self.mesh_comp.mesh = $MeshInstance3D.mesh
	
	FlecsScene.entity_add_component_instance(self.id, Components.Inventory.get_type_name(), self.inventory_comp)
	FlecsScene.entity_add_component_instance(self.id, Components.Interactable.get_type_name(), self.interactable_comp)
	FlecsScene.entity_add_component_instance(self.id, Components.PhysicsBody.get_type_name(), self.physics_body_comp)
	FlecsScene.entity_add_component_instance(self.id, Components.MeshComponent.get_type_name(), self.mesh_comp)

func _input(input_event: InputEvent) -> void:
	InteractionEventQueue.process_interactable_events(self.id, func(event : Components.InteractionEvent):
		if event.interaction == Components.Interaction.Use:
			
			# spawn entity
			var paint_can_id := self.spawn_system._make_paint_can(Color(randf(), randf(), randf()))
			var paint_can_phybod_comp : Components.PhysicsBody = FlecsScene.get_component_from_entity(paint_can_id, Components.PhysicsBody.get_type_name())
			var transform = paint_can_phybod_comp.get_transform()
			transform.origin = self.physics_body_comp.get_transform().origin
			transform.origin.x += 0.5
			transform.origin.y += 0.5
			paint_can_phybod_comp.set_transform(transform)
			
			# dispense
			var interactor_phybod_comp : Components.PhysicsBody = FlecsScene.get_component_from_entity(event.interactor, Components.PhysicsBody.get_type_name())
			var direction := interactor_phybod_comp.get_transform().origin - self.physics_body_comp.get_transform().origin
			var force := direction * 30 * Vector3(2, 2, 1)
			var pos := Vector3(randf_range(-10, 10), randf_range(-10, 10), randf_range(-10, 10))
			
			paint_can_phybod_comp.apply_position_force(force, pos)
			
			# spawn entity
			# var interactor_phybod_comp : Components.PhysicsBody = FlecsScene.get_component_from_entity(event.interactor, Components.PhysicsBody.get_type_name()) 
			#var can : PaintCan = paint_can_scene.instantiate() 
			# get_tree().current_scene.add_child(can)
			
			# dispense
			# var dispenser_origin : Vector3 = self.physics_body_comp.get_transform().origin
			# can.position = dispenser_origin
			# var can_origin : Vector3 = can.physics_body_comp.get_transform().origin
			# var interactor_origin : Vector3 = interactor_phybod_comp.get_transform().origin
			# var force : Vector3 = 60 * Vector3(1, 10, 1) * (can_origin - interactor_origin)
			#can.apply_position_force(force, can.position)
			
			# print("dispenser origin: %sx %sy %sz" % [dispenser_origin.x, dispenser_origin.y, dispenser_origin.z])
			# print("can origin: %sx %sy %sz" % [can_origin.x, can_origin.y, can_origin.z])
			# print("interactor origin: %sx %sy %sz" % [interactor_origin.x, interactor_origin.y, interactor_origin.z])
			# print("force: %sx %sy %sz" % [force.x, force.y, force.z])
			# var spawn_position = physics_body_comp.get_transform().origin
			# spawn_position.y += 3
			# spawn_position.z += 3
			# spawn_system._make_coin_default_shape(spawn_position)
	)

func _process(delta: float) -> void:
	# DebugDraw3D.draw_sphere(self.physics_body_comp.get_transform().origin, interaction_range, Color(0, 0, 255))
	pass
