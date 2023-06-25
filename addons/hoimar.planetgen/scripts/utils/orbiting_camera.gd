@tool
extends Node3D

@export var radius: float = 50.0: set = setRadius
@export var speed: float = 0.1
@export var _play_in_editor: bool = true

@onready var _camera = $Camera3D


func _ready():
	rotation_degrees.y = 0
	setRadius(radius)


func _process(delta):
	if Engine.is_editor_hint() and not _play_in_editor:
		return
	rotate(transform.basis.y.normalized(), speed * delta)


func setRadius(new):
	radius = new
	if _camera:
		_camera.position.z = radius
