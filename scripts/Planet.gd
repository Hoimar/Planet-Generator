tool
extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings = preload("res://resources/DefaultPlanetSettings.tres")
export(Material) var material: Material = preload("res://resources/DefaultPlanetMaterial.tres")

var faces: Array   # Stores the six basic faces that make up this planet.
var camera: Camera

onready var terrain = $terrain
onready var waterMesh = $waterMesh

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()

func _process(delta):
	if get_viewport().get_camera():
		for face in terrain.get_children():
			face.update(delta, get_viewport().get_camera().translation)

# Completely regenerate planet.
func generate():
	settings.init(self)
	for child in terrain.get_children():
		child.queue_free()
	waterMesh.mesh.radius = settings.radius
	waterMesh.mesh.height = settings.radius * 2.0
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, dir, settings.resolution, material)
		call_deferred("addTerrainFace", face)

func addTerrainFace(var face: TerrainFace):
	terrain.add_child(face)

func setDoGenerate(var new: bool):
	generate()
