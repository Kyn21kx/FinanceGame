class_name CameraSystem

var cameras_query := Query.new()
var targets_query := Query.new() 

func _ready() -> void:
  self.cameras_query.with_and_register(Components.Camera.get_type_name())

  self.cameras_query.with_and_register(Components.CameraFollow.get_type_name())
  self.cameras_query.with_and_register(Components.PhysicsBody.get_type_name())

func _physics_process(_delta : float) -> void:
  self.cameras_query.each(func process_cameras(camera_entity: RID, camera_components: Array):
    var camera : Components.Camera = camera_components[0]

    self.targets_query.each(func process_targets(target_entity: RID, target_components : Array):
      
      var target_camera_follow : Components.CameraFollow = target_components[0]
      var target_body : Components.PhysicsBody = target_components[1]

    )
  )

  pass