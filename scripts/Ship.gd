# Ship controller. Also handles the camera.
extends KinematicBody

const SHAKE_MAX_DEGREES := Vector3(0.005, 0.005, 0.015)
const SPEEDSTEP = 0.0005
const MAXSPEED = 1.5
const ROTATIONSPEED = 0.04
const MAXPARTICLETIME = 1.5

enum CAMERASTATE {FOLLOW, ROTATE}

var mouseSpeed := Vector2()
var currentSpeed: float
var cameraNoise = OpenSimplexNoise.new()

onready var cameraPivot = $CameraPivot
onready var camera = $CameraPivot/RotatingCamera
onready var cameraTween = $CameraPivot/Tween
onready var thrustParticlesLeft = $ThrustParticlesLeft
onready var thrustParticlesRight = $ThrustParticlesRight
onready var orgTransform = self.get_transform()
onready var orgPivotTransform = cameraPivot.get_transform()
onready var orgCameraRotation = camera.rotation


func _ready():
	cameraNoise.seed = randi()
	cameraNoise.period = 0.4
	if not Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_process_input(true)


func _physics_process(_delta):
	var input: Vector2 = Vector2()
	var rotationZ = 0
	
	# Ship movement input.
	if (Input.is_key_pressed(KEY_W)):
		input.x = 1
	if (Input.is_key_pressed(KEY_S)):
		input.x = -1
	if (Input.is_key_pressed(KEY_A)):
		input.y = 1
	if (Input.is_key_pressed(KEY_D)):
		input.y = -1
	if(Input.is_key_pressed(KEY_SHIFT)):
		input *= 10
	if (Input.is_key_pressed(KEY_Q)):
		rotationZ += ROTATIONSPEED
	if (Input.is_key_pressed(KEY_E)):
		rotationZ -= ROTATIONSPEED
	if(Input.is_action_just_pressed("toggle_camera_mode")):
		cameraTween.stop_all()
	if(Input.is_action_just_released("toggle_camera_mode")):
		if !cameraTween.is_active():
			cameraTween.interpolate_property(cameraPivot, "transform",
					cameraPivot.transform, orgPivotTransform, 1.2, Tween.TRANS_QUAD, Tween.EASE_OUT)
			cameraTween.start()
	
	if rotationZ:
		rotate(transform.basis.z, rotationZ)
	
	currentSpeed += SPEEDSTEP * input.x
	currentSpeed = clamp(currentSpeed, -MAXSPEED, MAXSPEED)
	if abs(currentSpeed) < SPEEDSTEP:
		currentSpeed = 0
	
	# Move the ship.
	transform.origin += -transform.basis.z * currentSpeed
	transform.origin += -transform.basis.x * currentSpeed * input.y
	
	shakeCamera()
	adjustThrusters()


func _input(event):
	if event is InputEventMouseMotion:
		mouseSpeed = event.relative * Global.MOUSE_SENSITIVITY
		if Input.is_action_pressed("toggle_camera_mode"):
			cameraPivot.rotate(cameraPivot.transform.basis.y.normalized(), deg2rad(-mouseSpeed.x))
			cameraPivot.rotate(cameraPivot.transform.basis.x.normalized(), deg2rad(-mouseSpeed.y))
		else:
			rotate(transform.basis.y, deg2rad(-mouseSpeed.x))
			rotate(transform.basis.x, deg2rad(-mouseSpeed.y))
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			currentSpeed += SPEEDSTEP
		elif event.button_index == BUTTON_WHEEL_DOWN:
			currentSpeed -= SPEEDSTEP


func shakeCamera():
	# Normalize the speed factor.
	var speedFactor: float = range_lerp(abs(currentSpeed), 0, MAXSPEED, 0, 1)
	# Apply an exponential easing function.
	speedFactor = 1.0 if speedFactor == 1 else 1 - pow(2, -10 * speedFactor)
	# Constant change in noise.
	var time = wrapf(Engine.get_frames_drawn()/float(Engine.iterations_per_second), 0, 1000)
	camera.rotation = orgCameraRotation
	camera.rotation.x = SHAKE_MAX_DEGREES.x * cameraNoise.get_noise_1d(time) * speedFactor
	camera.rotation.y = SHAKE_MAX_DEGREES.y * cameraNoise.get_noise_1d(time*2) * speedFactor
	camera.rotation.z = SHAKE_MAX_DEGREES.z * cameraNoise.get_noise_1d(time*3) * speedFactor


func adjustThrusters():
	var lifetime = range_lerp(abs(currentSpeed), 0, MAXSPEED, 0, MAXPARTICLETIME)
	lifetime = 1.0 if lifetime == 1 else 1 - pow(2, -10 * lifetime)
	thrustParticlesLeft.visible = lifetime > 0
	thrustParticlesRight.visible = lifetime > 0
	thrustParticlesLeft.lifetime = max(0.01, lifetime)
	thrustParticlesRight.lifetime = max(0.01, lifetime)
