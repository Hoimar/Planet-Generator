extends KinematicBody
# Ship controller. Also handles the camera.

const SHAKE_MAX_DEGREES := Vector3(0.005, 0.005, 0.015)
const SPEEDSTEP = 0.0005
const MAXSPEED = 1.1
const ROTATIONSPEED = 0.01
const MAXPARTICLETIME = 1.5

enum CAMERASTATE {FOLLOW, ROTATE}

var _mouse_speed := Vector2()
var _current_speed: float
var _camera_noise := OpenSimplexNoise.new()

onready var _camera_pivot := $CameraPivot
onready var _camera := $CameraPivot/RotatingCamera
onready var _camera_tween := $CameraPivot/Tween
onready var _thrust_particles_left := $ThrustParticlesLeft
onready var _thrust_particles_right := $ThrustParticlesRight
onready var _org_transform := self.get_transform()
onready var _org_pivot_transform: Transform = _camera_pivot.get_transform()
onready var _org_camera_rotation: Vector3 = _camera.rotation


func _ready():
	_camera_noise.seed = randi()
	_camera_noise.period = 0.4
	if not Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_process_input(true)


func _physics_process(_delta):
	var input: Vector2 = Vector2()
	var rotation_z = 0
	# Ship movement input.
	if Input.is_key_pressed(KEY_W):
		input.x = 1
	if Input.is_key_pressed(KEY_S):
		input.x = -1
	if Input.is_key_pressed(KEY_A):
		input.y = 1
	if Input.is_key_pressed(KEY_D):
		input.y = -1
	if Input.is_key_pressed(KEY_SHIFT):
		input *= 10
	if Input.is_key_pressed(KEY_Q):
		rotation_z += ROTATIONSPEED
	if Input.is_key_pressed(KEY_E):
		rotation_z -= ROTATIONSPEED
	if Input.is_action_just_pressed("toggle_camera_mode"):
		_camera_tween.stop_all()
	if Input.is_action_just_released("toggle_camera_mode"):
		if !_camera_tween.is_active():
			_camera_tween.interpolate_property(_camera_pivot, "transform",
					_camera_pivot.transform, _org_pivot_transform, 1.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
			_camera_tween.start()

	if rotation_z:
		rotate(transform.basis.z, rotation_z)

	_current_speed += SPEEDSTEP * input.x
	_current_speed = clamp(_current_speed, -MAXSPEED, MAXSPEED)
	if abs(_current_speed) < SPEEDSTEP:
		_current_speed = 0

	# Move the ship.
	transform.origin += -transform.basis.z * _current_speed
	transform.origin += -transform.basis.x * _current_speed * input.y

	shake_camera()
	adjust_thrusters()


func _input(event):
	if event is InputEventMouseMotion:
		_mouse_speed = event.relative * PGGlobals.MOUSE_SENSITIVITY
		if Input.is_action_pressed("toggle_camera_mode"):
			_camera_pivot.rotate(_camera_pivot.transform.basis.y.normalized(), deg2rad(-_mouse_speed.x))
			_camera_pivot.rotate(_camera_pivot.transform.basis.x.normalized(), deg2rad(-_mouse_speed.y))
		else:
			rotate(transform.basis.y, deg2rad(-_mouse_speed.x))
			rotate(transform.basis.x, deg2rad(-_mouse_speed.y))
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			_current_speed += SPEEDSTEP
		elif event.button_index == BUTTON_WHEEL_DOWN:
			_current_speed -= SPEEDSTEP


func shake_camera():
	# Normalize the speed factor.
	var speed_factor: float = range_lerp(abs(_current_speed), 0, MAXSPEED, 0, 1)
	# Apply an exponential easing function.
	speed_factor = 1.0 if speed_factor == 1 else 1 - pow(2, -10 * speed_factor)
	# Constant change in noise.
	var time = wrapf(Engine.get_frames_drawn() / float(Engine.iterations_per_second), 0, 1000)
	_camera.rotation = _org_camera_rotation
	_camera.rotation.x = SHAKE_MAX_DEGREES.x * _camera_noise.get_noise_1d(time) * speed_factor
	_camera.rotation.y = SHAKE_MAX_DEGREES.y * _camera_noise.get_noise_1d(time*2) * speed_factor
	_camera.rotation.z = SHAKE_MAX_DEGREES.z * _camera_noise.get_noise_1d(time*3) * speed_factor


func adjust_thrusters():
	var lifetime = range_lerp(abs(_current_speed), 0, MAXSPEED, 0, MAXPARTICLETIME)
	lifetime = 1.0 if lifetime == 1 else 1 - pow(2, -10 * lifetime)
	_thrust_particles_left.visible = lifetime > 0
	_thrust_particles_right.visible = lifetime > 0
	_thrust_particles_left.lifetime = max(0.01, lifetime)
	_thrust_particles_right.lifetime = max(0.01, lifetime)
