tool
extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) onready var doGenerate: bool = false setget set_do_generate
export(int) onready var seed_value: int = 0 setget set_seed
export(int, 3, 10000, 1) onready var resolution: int = 20 setget set_resolution


var faces: Array   # Stores the six faces that make up this planet.
var noiseGenerator: NoiseGenerator

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()

func _process(delta):
	#if Engine.is_editor_hint():
	#	return
	for face in get_children():
		face.update(delta, get_viewport().get_camera().translation)

func generate():
	if not Engine.is_editor_hint():
		yield(self, "ready")
	for child in get_children():
		child.queue_free()
	
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.generate(self, dir, resolution, preload("res://resources/Planet.tres"))
		add_child(face)

func set_do_generate(var new: bool):
	generate()

func set_seed(var new: int):
	seed_value = new
	generate()

func set_resolution(var new: int):
	resolution = new
	generate()
