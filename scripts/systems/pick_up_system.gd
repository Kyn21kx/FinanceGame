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
	self.collectors_query.with_and_register(Components.Inventory.get_type_name())


func _physics_process(_delta: float) -> void:
	self.collectables_query.each(func process_collectables(collectable_entity: RID, components: Array):
		var collectable : Components.Collectable = components[0]
		var collectable_phy : Components.PhysicsBody = components[1]
		var collectable_mesh : Components.MeshComponent = components[2]
		
		self.collectors_query.each(func process_collectors(_collector_entity: RID, collectors_components: Array):
			var collector : Components.Collector = collectors_components[0]
			var collector_phy : Components.PhysicsBody = collectors_components[1]
			var collector_inv : Components.Inventory = collectors_components[2]
			
			var collector_xform : Transform3D = collector_phy.get_transform()
			var collectable_xform : Transform3D = collectable_phy.get_transform()

			var distance = collectable_xform.origin.distance_to(collector_xform.origin)
			
			if distance > collector.attraction_range:
				return
			
			var direction : Vector3 = collector_xform.origin - collectable_xform.origin 
			var velocity = direction * collector.attraction_factor / collectable.weight
			
			collectable_phy.set_velocity(velocity)
			
			if distance > collector.pickup_range:
				return
			
			collector_inv.add(collectable.item, collectable.amount)
			
			update_inventory_display(collector_inv)
			
			FlecsScene.destroy_raw_entity(collectable_entity, func destructor():
				PhysicsServer3D.body_remove_shape(collectable_phy.body_id, 0)
				RenderingServer.free_rid(collectable_mesh.instance)
				PhysicsServer3D.free_rid(collectable_phy.body_id)
			)
		)
	)


func update_inventory_display(inventory : Components.Inventory):
	var display : Label = $"../CountDisplay"
	
	display.text = ""
	display.text += "Coins: %d \n" % inventory.coins
	display.text += "Ingots: %d \n" % inventory.ingots
