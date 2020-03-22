extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) var doGenerate: bool = false setget set_do_generate
export(int) var seed_value: int = 0 setget set_seed
export(int, 3, 10000, 1) var resolution: int = 20 setget set_resolution
export(float)  var radius: float = 1 setget set_radius
export(Material) var material: Material = preload("res://resources/Planet.tres")

var faces: Array   # Stores the six faces that make up this planet.
var noiseGenerator: NoiseGenerator

var camera: Spatial

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()
	camera = get_tree().get_nodes_in_group("camera")[0]

func _process(delta):
	for face in get_children():
		face.update(delta, camera.translation)

func generate():
	yield(self, "ready")
	for child in get_children():
		child.queue_free()
	
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.generate(self, dir, resolution, material)
		add_child(face)

func set_do_generate(var new: bool):
	generate()

func set_seed(var new: int):
	seed_value = new
	generate()

func set_resolution(var new: int):
	resolution = new
	generate()

func set_radius(var new: float):
	radius = new
	generate()
