extends Node3D

const Constants := preload("../constants.gd")

@export var _radius: float = 0.6: get = get_radius, set = set_radius

@onready var _camera := $Camera3D
@onready var _org_rotation := transform.basis.get_euler()

#tween camera back to original pos
func _process(delta):
	if Input.is_action_just_released("toggle_camera_mode"):
		var _tween = create_tween()
		_tween.tween_property(self, "rotation", _org_rotation, 1.2).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
		_tween.play()

#Use mouse to rotate camera
func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and Input.is_action_pressed("toggle_camera_mode"):
		var _mouse_speed = event.relative * Constants.MOUSE_SENSITIVITY * 0.05
		rotate(transform.basis.y.normalized(), deg_to_rad(-_mouse_speed.x))
		rotate(transform.basis.x.normalized(), deg_to_rad(-_mouse_speed.y))

func set_radius(new: float):
	_radius = new
	_camera.transform.origin = Vector3.ZERO
	_camera.translate_object_local(Vector3(0, 0, _radius))

func get_radius():
	return _radius
