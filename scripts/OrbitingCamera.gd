tool
extends Spatial

export(float) var radius: float = 50.0 setget setRadius
export(float) var speed: float = 0.01
export(bool) var playInEditor: bool = true

onready var camera = $Camera

func _ready():
	rotation_degrees.y = 0
	setRadius(radius)

func _process(delta):
	if Engine.editor_hint and !playInEditor:
		return
	rotate(transform.basis.y.normalized(), speed)

func setRadius(var new):
	radius = new
	if camera:
		camera.translation.z = radius
