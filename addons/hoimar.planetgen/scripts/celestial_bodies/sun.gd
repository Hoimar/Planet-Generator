@tool
@icon("../../resources/icons/sun.svg")
class_name Sun
extends Planet

const CORONA_SIZE := Vector2(15, 14)
const LIGHT_OFFSET := 1.01 * Vector3.FORWARD

@onready var _corona: MeshInstance3D = $Corona
@onready var _sunlight := $Sunlight


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	var cam = get_viewport().get_camera_3d()
	if cam:
		look_at(cam.global_transform.origin, Vector3.UP)


func generate():
	await self.ready
	if settings:
		_corona.mesh.size = CORONA_SIZE * settings.radius
		_sunlight.position = LIGHT_OFFSET * settings.radius
	super.generate()


func _get_configuration_warnings():
	return _get_common_config_warning()
