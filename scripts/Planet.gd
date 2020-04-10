tool
extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings = preload("res://resources/EarthlikePlanetSettings.tres")
export(Material) var material: Material = preload("res://resources/EarthlikePlanetMaterial.tres")

var faces: Array   # Stores the six basic faces that make up this planet.
var camera: Camera

onready var terrain = $terrain
onready var water = $water
onready var atmosphere = $atmosphere
onready var light = $"../DirectionalLight"

# Called when the node enters the scene tree for the first time.
func _ready():
	generate()

func _process(delta):
	if get_viewport().get_camera():
		for face in terrain.get_children():
			face.update(delta, get_viewport().get_camera().global_transform.origin)
	if light:
		atmosphere.look_at(-light.global_transform.origin, Vector3.UP)

# Completely regenerate planet.
func generate():
	settings.init(self)
	for child in terrain.get_children():
		child.queue_free()
	water.mesh.radius = settings.radius
	water.mesh.height = settings.radius * 2.0
	atmosphere.mesh.size = Vector3(settings.radius*2.5, settings.radius*2.5, settings.radius*2.5)
	var shaderMat: ShaderMaterial = atmosphere.mesh.surface_get_material(0)
	shaderMat.set_shader_param("planet_radius", settings.radius)
	shaderMat.set_shader_param("atmo_radius", settings.radius * settings.atmosphereThickness)

	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, dir, settings.resolution, material)
		call_deferred("addTerrainFace", face)

func addTerrainFace(var face: TerrainFace):
	terrain.add_child(face)

func setDoGenerate(var new: bool):
	generate()
