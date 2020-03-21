extends WorldEnvironment

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

onready var camera = $Camera


func _process(delta):
	if Input.is_key_pressed(KEY_UP):
		camera.translation.z -= .01
	if Input.is_key_pressed(KEY_DOWN):
		camera.translation.z += .01

