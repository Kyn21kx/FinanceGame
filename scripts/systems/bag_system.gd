extends Node
class_name BagSystem

var players_query := Query.new()
var bags_query := Query.new()

func _ready() -> void:
	self.players_query.with_and_register(Components.Player.get_type_name())
	self.players_query.with_and_register(Components.Controller.get_type_name())
	self.players_query.with_and_register(Components.PhysicsBody.get_type_name())
	self.bags_query.with_and_register(Components.Bag.get_type_name())
	self.bags_query.with_and_register(Components.PhysicsBody.get_type_name())

func _physics_process(_delta: float):
	self.players_query.each(func _iter_players(player_entity: RID, components: Array):
		var controller : Components.Controller = components[1]
		var player_body : Components.PhysicsBody = components[2]

		var player_xform : Transform3D = player_body.get_transform()


		# var axis_direction : Vector2 = controller.get_axis_left().normalized()

		self.bags_query.each(func _iter_bags(_bag_entity: RID, bag_components: Array):
			var bag_info : Components.Bag = bag_components[0]
			var bag_body : Components.PhysicsBody = bag_components[1]
			var bag_xform : Transform3D = bag_body.get_transform()

			var distance_to_bag_sqr : float = player_xform.origin.distance_squared_to(bag_xform.origin) 


			const threshold := 16
			if distance_to_bag_sqr > threshold:
				return

			# This is laid out like this for debug purposes, move the if statement up so this does not evaluate all the time
			DebugDraw3D.draw_text(player_xform.origin + (Vector3.RIGHT * 2), "Able to hit!", 56)
			if !Input.is_key_pressed(controller.hit_key) || bag_info.last_player_id == player_entity:
				return
			bag_body.apply_impulse(Vector3.UP * 5)
			bag_info.last_player_id = player_entity
		)
	)
	pass

