class_name CameraSystem extends Camera3D


var query := Query.new()
var all_targets_in_frustrum: bool = true
var target_position_avg: Vector3
var current_look_position: Vector3
var target_count: int = 0
@export
var fov_min: float
@export
var fov_max: float

func _ready() -> void:
	self.query.with_and_register(Components.CameraTarget.get_type_name())
	self.query.with_and_register(Components.PhysicsBody.get_type_name())
	self.query.cache_mode(Query.Cached)

func _process(delta: float) -> void:
	self.all_targets_in_frustrum = true
	self.target_count = 0
	self.target_position_avg = Vector3.ZERO
	self.query.each(func _iter_targets(_entity: RID, components: Array):
		# Check if the target is in the frustrum, if they are not, zoom out
		var body : Components.PhysicsBody = components[1]
		var velocity_direction := body.get_velocity().normalized()
		var target_origin := body.get_transform().origin
		self.target_count += 1
		self.target_position_avg += target_origin
		if !self.is_position_in_frustum(target_origin + velocity_direction * 5):
			self.all_targets_in_frustrum = false
		pass
	)
	self.target_position_avg /= self.target_count
	self.current_look_position = lerp(self.current_look_position, self.target_position_avg, delta * 3)
	var euler : Vector3 = self.rotation_degrees
	self.look_at(self.current_look_position)
	self.rotation_degrees.z = euler.z
	const error := 2
	if (self.all_targets_in_frustrum):
		# self.fov = lerpf(self.fov, self.fov_min, delta)
		var diff : float = absf(self.fov - self.fov_min)
		if (diff <= error): return
		self.fov = lerpf(self.fov, self.fov_min, delta)
		return
	var diff : float = absf(self.fov - self.fov_max)
	if (diff <= error): return
	self.fov = lerpf(self.fov, self.fov_max, delta)
	pass
