extends KinematicBody

const X_AXIS = Vector3(1, 0, 0)
const Y_AXIS = Vector3(0, 1, 0)

# Input parameters.
export(float) var mouseSensitivity = 0.05
export(float) var speedStep = 0.0005
export(float) var maxSpeed = 10.0
export(float) var rotationSpeed = 0.03

var mouseSpeed: Vector2 = Vector2()
var currentSpeed: float

onready var orgTransform = self.get_transform()


func _ready():
	if not Engine.editor_hint:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	set_process_input(true)

func _physics_process(delta):
	var input: Vector2 = Vector2()
	var rotationZ = 0
	
	if (Input.is_key_pressed(KEY_W)):
		input.x = 1
	if (Input.is_key_pressed(KEY_S)):
		input.x = -1
	if (Input.is_key_pressed(KEY_A)):
		input.y = 1
	if (Input.is_key_pressed(KEY_D)):
		input.y = -1
	if (Input.is_key_pressed(KEY_Q)):
		rotationZ += rotationSpeed
	if (Input.is_key_pressed(KEY_E)):
		rotationZ -= rotationSpeed
	if(Input.is_key_pressed(KEY_SHIFT)):
		input *= 10
	
	if rotationZ:
		rotate(transform.basis.z, rotationZ)
	
	currentSpeed = clamp(currentSpeed, -maxSpeed, maxSpeed)
	currentSpeed += speedStep * input.x
	if abs(currentSpeed) < speedStep:
		currentSpeed = 0
	
	transform.origin += -transform.basis.z * currentSpeed
	transform.origin += -transform.basis.x * currentSpeed * input.y


func _input(event):
	if event is InputEventMouseMotion:
		mouseSpeed = event.relative * mouseSensitivity
		rotate(transform.basis.y, deg2rad(-mouseSpeed.x))
		rotate(transform.basis.x, deg2rad(-mouseSpeed.y))
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			currentSpeed += speedStep
		elif event.button_index == BUTTON_WHEEL_DOWN:
			currentSpeed -= speedStep
