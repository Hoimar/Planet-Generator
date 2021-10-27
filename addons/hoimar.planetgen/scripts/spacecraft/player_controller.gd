extends Node

const Ship := preload("ship.gd")
const Constants := preload("../constants.gd")

var _mouse_speed := Vector2.ZERO
export onready var ship_path := $".."
onready var ship: RigidBody = ship_path


func _ready():
	if not Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _physics_process(delta):
	var input := Vector3()
	var rotation_z := 0.0
	# Ship movement input.
	if Input.is_key_pressed(KEY_W):
		input.z = -1
	if Input.is_key_pressed(KEY_S):
		input.z = 1
	if Input.is_key_pressed(KEY_A):
		input.x = -1
	if Input.is_key_pressed(KEY_D):
		input.x = 1
	# Rotation along local Z axis.
	if Input.is_key_pressed(KEY_Q):
		rotation_z = Ship.ROTATIONSPEED
	if Input.is_key_pressed(KEY_E):
		rotation_z = -Ship.ROTATIONSPEED
	if rotation_z:
		ship.rotate(ship.transform.basis.z, rotation_z)
	
	if input:
		ship.apply_thrust(input)


func _input(event):
	if     event is InputEventMouseMotion \
	   and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED \
	   and not Input.is_action_pressed("toggle_camera_mode"):
		_mouse_speed = event.relative * Constants.MOUSE_SENSITIVITY
		ship.rotate(ship.transform.basis.y.normalized(), deg2rad(-_mouse_speed.x))
		ship.rotate(ship.transform.basis.x.normalized(), deg2rad(-_mouse_speed.y))
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			ship.speed_scale += Ship.SPEED_INCREMENT
		elif event.button_index == BUTTON_WHEEL_DOWN:
			ship.speed_scale -= Ship.SPEED_INCREMENT
