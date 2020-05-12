tool
extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
const WATERMATERIAL: Material = preload("res://resources/WaterMaterial.tres")
const WATERSETTINGS: PlanetSettings = preload("res://resources/WaterSettings.tres")

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings
export(Material) var material: Material

var orgAtmoMesh: Mesh
var atmoMaterial: ShaderMaterial

onready var terrain: TerrainContainer = $terrain
onready var water: TerrainContainer = $water
onready var waterSphere: MeshInstance = $waterSphere
onready var atmosphere = $atmosphere
onready var sun = get_node("../Sun")


# Called when the node enters the scene tree for the first time.
func _ready():
	if !orgAtmoMesh:
		orgAtmoMesh = atmosphere.mesh
	generate()


func _physics_process(delta):
	var camera = get_viewport().get_camera()
	if camera and settings.hasAtmosphere:
		# Update atmosphere shader.
		var distance: float = global_transform.origin.distance_to(camera.global_transform.origin)
		var minScale: float = 1.0
		var maxScale: float = 1.06
		var scale: float = range_lerp(distance, settings.radius*1.75, settings.radius*5,
									  minScale, maxScale)
		scale = max(minScale, min(scale, maxScale))
		atmoMaterial.set_shader_param("planet_radius", settings.radius*scale)
		atmoMaterial.set_shader_param("atmo_radius", settings.radius*settings.atmosphereThickness*scale)
		if sun and self != sun:
			atmosphere.look_at(-sun.global_transform.origin, Vector3.UP)


# Generate whole planet.
func generate():
	var time_before = OS.get_ticks_msec()
	if not settings or not material:
		print("Warning: Can't generate, settings or material for ", self, " is null.")
		return
	settings.init(self)
	
	terrain.generate(settings, material)
	
	# Adjust water.
	water.visible = settings.hasWater
	if settings.hasWater:
		var waterSettings = WATERSETTINGS.duplicate()
		waterSettings.radius = settings.radius
		waterSettings.init(self)
		water.generate(waterSettings, WATERMATERIAL)
		#waterSphere.mesh.radius = settings.radius
		#waterSphere.mesh.height = settings.radius*2
	
	# Adjust atmosphere.
	atmosphere.visible = settings.hasAtmosphere
	if settings.hasAtmosphere:
		atmosphere.mesh = orgAtmoMesh.duplicate(true)
		atmoMaterial = atmosphere.mesh.surface_get_material(0)
		atmosphere.mesh.size = Vector3(settings.radius*2.5, settings.radius*2.5, settings.radius*2.5)
		atmoMaterial.set_shader_param("planet_radius", settings.radius)
		atmoMaterial.set_shader_param("atmo_radius", settings.radius * settings.atmosphereThickness)
	
	print(str(self) + ", " + name + ", took: " + str(OS.get_ticks_msec() - time_before) + "ms for generate()")


func setDoGenerate(var new: bool):
	generate()
