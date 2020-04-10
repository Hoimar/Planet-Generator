extends Spatial

export(float) var mouseSensitivity = 0.025
export(float) var cameraSpeed = 0.05
export(float) var speedStep = 0.0005
export(float) var maxSpeed = 0.2
export(float) var rotationSpeed = 0.01

const X_AXIS = Vector3(1, 0, 0)
const Y_AXIS = Vector3(0, 1, 0)

var is_mouse_motion = false

var mouseSpeed = Vector2()
var mouseSpeedX = 0
var mouseSpeedY = 0

onready var cameraTransform = self.get_transform()

func _ready():
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	set_physics_process(true)
	set_process_input(true)


func _physics_process(delta):
	var rot_x = Quat(X_AXIS, -mouseSpeedY)
	var rot_y = Quat(Y_AXIS, -mouseSpeedX)
	var rotationZ = 0
	
	if (Input.is_key_pressed(KEY_W)):
		cameraTransform.origin += -self.get_transform().basis.z * cameraSpeed
	
	if (Input.is_key_pressed(KEY_S)):
		cameraTransform.origin += self.get_transform().basis.z * cameraSpeed
	
	if (Input.is_key_pressed(KEY_A)):
		cameraTransform.origin += -self.get_transform().basis.x * cameraSpeed
	
	if (Input.is_key_pressed(KEY_D)):
		cameraTransform.origin += self.get_transform().basis.x * cameraSpeed
	
	if (Input.is_key_pressed(KEY_Q)):
		rotationZ += rotationSpeed
	
	if (Input.is_key_pressed(KEY_E)):
		rotationZ -= rotationSpeed
	
	cameraTransform.basis = cameraTransform.basis.rotated(get_transform().basis.z, rotationZ)
	set_transform(  cameraTransform
				  * Transform(rot_y)
				  * Transform(rot_x))

func _input(event):
	mouseSpeed = Vector2(0, 0)
	if event is InputEventMouseMotion:
		mouseSpeed = event.relative * mouseSensitivity
	elif event is InputEventMouseButton:
		if event.button_index == BUTTON_WHEEL_UP:
			cameraSpeed += speedStep
		elif event.button_index == BUTTON_WHEEL_DOWN:
			cameraSpeed -= speedStep
		cameraSpeed = clamp(cameraSpeed, 0, maxSpeed)

	mouseSpeedX += mouseSpeed.x * mouseSensitivity
	mouseSpeedY += mouseSpeed.y * mouseSensitivity

