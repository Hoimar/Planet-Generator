extends Spatial

const X_AXIS = Vector3(1, 0, 0)
const Y_AXIS = Vector3(0, 1, 0)

# Input parameters.
export(float) var mouseSensitivity = 0.025
export(float) var speedStep = 0.0005
export(float) var maxSpeed = 1.0
export(float) var rotationSpeed = 0.01

# Mouse variables.
var is_mouse_motion = false
var mouseSpeed = Vector2()
var mouseSpeedX = 0
var mouseSpeedY = 0

var currentSpeed = 0.05
var speed: Vector3

onready var orgTransform = self.get_transform()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	#$InterpolatedCamera.set_as_toplevel(true)
	set_physics_process(true)
	set_process_input(true)


func _physics_process(delta):
	var rot_x = Quat(X_AXIS, -mouseSpeedY)
	var rot_y = Quat(Y_AXIS, -mouseSpeedX)
	var rotationZ = 0

	if (Input.is_key_pressed(KEY_W)):
		orgTransform.origin += -self.get_transform().basis.z * currentSpeed
	if (Input.is_key_pressed(KEY_S)):
		orgTransform.origin += self.get_transform().basis.z * currentSpeed
	if (Input.is_key_pressed(KEY_A)):
		orgTransform.origin += -self.get_transform().basis.x * currentSpeed
	if (Input.is_key_pressed(KEY_D)):
		orgTransform.origin += self.get_transform().basis.x * currentSpeed
	if (Input.is_key_pressed(KEY_Q)):
		rotationZ += rotationSpeed
	if (Input.is_key_pressed(KEY_E)):
		rotationZ -= rotationSpeed
	if (Input.is_key_pressed(KEY_PAGEUP)):
		setSpeed(currentSpeed + speedStep * 3)
	if (Input.is_key_pressed(KEY_PAGEDOWN)):
		setSpeed(currentSpeed - speedStep * 3)
	currentSpeed = clamp(currentSpeed, 0, maxSpeed)
	
	orgTransform.basis = orgTransform.basis.rotated(get_transform().basis.z, rotationZ)
	set_transform(  orgTransform
				  * Transform(rot_y)
				  * Transform(rot_x))

func _input(event):
	mouseSpeed = Vector2(0, 0)
	if event is InputEventMouseMotion:
		mouseSpeed = event.relative * mouseSensitivity
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			setSpeed(currentSpeed + speedStep)
		elif event.button_index == BUTTON_WHEEL_DOWN:
			setSpeed(currentSpeed - speedStep)
	mouseSpeedX += mouseSpeed.x * mouseSensitivity
	mouseSpeedY += mouseSpeed.y * mouseSensitivity

func setSpeed(var new):
	currentSpeed = new
