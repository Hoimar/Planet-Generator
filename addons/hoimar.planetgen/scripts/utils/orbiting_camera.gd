tool
extends Spatial

export(float) var radius: float = 50.0 setget setRadius
export(float) var speed: float = 0.1
export(bool) var _play_in_editor: bool = true

onready var _camera = $Camera


func _ready():
	rotation_degrees.y = 0
	setRadius(radius)


func _process(delta):
	if Engine.editor_hint and not _play_in_editor:
		return
	rotate(transform.basis.y.normalized(), speed * delta)


func setRadius(var new):
	radius = new
	if _camera:
		_camera.translation.z = radius
