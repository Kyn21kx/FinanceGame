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

func _process(delta: float) -> void:
	# this proces happends in three stages:
	
	self.collectables_query.each(func process_collectables(components: Array):
		var collectable : Components.Collectable = components[0]
		var collectable_phy : Components.PhysicsBody = components[1]
		var collectable_mesh : Components.MeshComponent = components[2]
		
		self.collectors_query.each(func process_collectors(components: Array):
			var collector : Components.Collector = components[0]
			var collector_phy : Components.PhysicsBody = components[1]
			
			# 1. check if there are any collectables on range
			
			var distance = collectable_phy.get_transform().origin.distance_to(collector_phy.get_transform().origin)
			
			if distance > collector.attraction_range:
				return
			
			# 2. if so, move the collectables closer to "the collector" (the player)
			
			var t = collectable_phy.get_transform()
			
			t.origin = collectable_phy.get_transform().origin.lerp(collector_phy.get_transform().origin, collector.attraction_factor * delta)
			
			collectable_phy.set_transform(t)
			
			# 3. if any collectable is close enough pick it up
			
			if distance > collector.pickup_range:
				return
			
			#FlecsScene.destroy_raw_entity(collectable)
			#FlecsScene.destroy_raw_entity(collectable_phy.shape)
			#FlecsScene.destroy_raw_entity(collectable_mesh.instance)
			#FlecsScene.destroy_raw_entity(collectable_phy.body_id)
			#PhysicsServer3D.free_rid(collectable_phy.shape)
			#RenderingServer.free_rid(collectable_mesh.instance)
			# PhysicsServer3D.free_rid(collectable_phy.body_id)
			
			t.origin.x = -1000;
			t.origin.y = -1000;
			collectable_phy.set_transform(t) # TODO: actually destroy the object, this is just not right
			
			if collector.inventory.has(collectable.type) == false:
				collector.inventory[collectable.type] = 0
			
			collector.inventory[collectable.type] = collector.inventory[collectable.type] + 1
			$"../CountDisplay".text = "Coins: %d" % collector.inventory[collectable.type]
		)
	)
	
	return;
