tool
extends Planet

func _ready():
	._ready()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	var cam = get_viewport().get_camera()
	if cam:
		look_at(cam.global_transform.origin, Vector3.UP)

func generate():
	if settings:
		$corona.mesh.size = Vector2(settings.radius * 15, settings.radius * 14);
		$sunlight.translation = Vector3.FORWARD * settings.radius * 1.01
	.generate()
