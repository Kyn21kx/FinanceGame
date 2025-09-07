extends Node
class_name PickUpSystem

var collectables_query := Query.new()
var collectors_query := Query.new()

func _ready() -> void:
	self.collectables_query.with_and_register(Components.Collectable.get_type_name())
	self.collectables_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.collectables_query.with_and_register(Components.MeshComponent.get_type_name())
	self.collectors_query.with_and_register(Components.Collector.get_type_name())
	self.collectors_query.with_and_register(Components.PhysicsBody.get_type_name())

func _physics_process(delta: float) -> void:
	# This process happens in three stages:
	
	self.collectables_query.each(func process_collectables(collectable_entity: RID, components: Array):
		var collectable : Components.Collectable = components[0]
		var collectable_phy : Components.PhysicsBody = components[1]
		var collectable_mesh : Components.MeshComponent = components[2]
		
		self.collectors_query.each(func process_collectors(_collector_entity: RID, collectors_components: Array):
			var collector : Components.Collector = collectors_components[0]
			var collector_phy : Components.PhysicsBody = collectors_components[1]
			
			var distance = collectable_phy.get_transform().origin.distance_to(collector_phy.get_transform().origin)
			
			if distance > collector.attraction_range:
				return
			
			var direction : Vector3 = collector_phy.get_transform().origin - collectable_phy.get_transform().origin 
			var velocity = direction * collector.attraction_factor / collectable.weight
			
			collectable_phy.set_velocity(velocity)
			
			if distance > collector.pickup_range:
				return
			
			collector.add_collectable_to_inventory(collectable)
			$"../CountDisplay".text = "Coins: %d" % collector.get_in_inventory(collectable.type)

			FlecsScene.destroy_raw_entity(collectable_entity, func destructor():
				PhysicsServer3D.body_remove_shape(collectable_phy.body_id, 0)
				RenderingServer.free_rid(collectable_mesh.instance)
				PhysicsServer3D.free_rid(collectable_phy.body_id)
			)
		)
	)
	
	return;
