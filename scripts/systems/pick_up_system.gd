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
	
	self.collectables_query.each(func process_collectables(_entity: RID, components: Array):
		var collectable : Components.Collectable = components[0]
		var collectable_phy : Components.PhysicsBody = components[1]
		var collectable_mesh : Components.MeshComponent = components[2]
		
		self.collectors_query.each(func process_collectors(_entity: RID, collectors_components: Array):
			var collector : Components.Collector = collectors_components[0]
			var collector_phy : Components.PhysicsBody = collectors_components[1]
			
			# 1. check if there are any collectables on range
			var distance = collectable_phy.get_transform().origin.distance_to(collector_phy.get_transform().origin)
			
			if distance > collector.attraction_range:
				return
			
			# 2. if so, move the collectables closer to "the collector" (the player)
			var direction : Vector3 = collector_phy.get_transform().origin - collectable_phy.get_transform().origin 
			var velocity = direction * collector.attraction_factor / collectable.weight
			
			collectable_phy.set_velocity(velocity)
			
			# 3. if any collectable is close enough pick it up
			if distance > collector.pickup_range:
				return
			
			#FlecsScene.destroy_raw_entity(collectable)
			#FlecsScene.destroy_raw_entity(collectable_phy.shape)
			#FlecsScene.destroy_raw_entity(collectable_mesh.instance)
			#FlecsScene.destroy_raw_entity(collectable_phy.body_id)
			#PhysicsServer3D.free_rid(collectable_phy.shape)
			#RenderingServer.free_rid(collectable_mesh.instance)
			#PhysicsServer3D.free_rid(collectable_phy.body_id)
			
			var t = collectable_phy.get_transform()
			t.origin.x = -1000;
			t.origin.y = -1000;
			collectable_phy.set_transform(t) # TODO: actually destroy the object, this is just not right
			
			collector.add_collectable_to_inventory(collectable)
			
			$"../CountDisplay".text = "Coins: %d" % collector.get_in_inventory(collectable.type)
		)
	)
	
	return;
