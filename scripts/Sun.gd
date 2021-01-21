tool
extends Planet

const CORONA_SIZE := Vector2(15, 14)
const LIGHT_OFFSET := 1.01 * Vector3.FORWARD


func _ready():
	._ready()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var cam = get_viewport().get_camera()
	if cam:
		look_at(cam.global_transform.origin, Vector3.UP)


func generate():
	if settings:
		$corona.mesh.size = CORONA_SIZE * settings.radius
		$sunlight.translation = LIGHT_OFFSET * settings.radius
	.generate()
