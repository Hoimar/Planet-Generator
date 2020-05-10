tool
extends Spatial

class_name Planet

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings
export(Material) var material: Material

var faces: Array   # Stores the six basic faces that make up this planet.
var camera: Camera

var orgWaterMesh: Mesh
var orgAtmoMesh: Mesh
var atmoMaterial: ShaderMaterial

onready var terrain = $terrain
onready var water = $water
onready var atmosphere = $atmosphere
onready var sun = get_node("../Sun")


# Called when the node enters the scene tree for the first time.
func _ready():
	if !orgWaterMesh:
		orgWaterMesh = water.mesh
	if !orgAtmoMesh:
		orgAtmoMesh = atmosphere.mesh
	generate()


func _physics_process(delta):
	var camera = get_viewport().get_camera()
	if camera:
		# Update terrain faces.
		for face in terrain.get_children():
			face.update(delta, get_viewport().get_camera().global_transform.origin)
		if settings.hasAtmosphere:
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
	for child in terrain.get_children():
		child.queue_free()
	water.visible = settings.hasWater
	if settings.hasWater:
		# Adjust water.
		water.mesh = orgWaterMesh.duplicate(true)
		water.mesh.radius = settings.radius
		water.mesh.height = settings.radius * 2.0
		var waterMat: ShaderMaterial = water.mesh.surface_get_material(0)
		waterMat.set_shader_param("planet_radius", settings.radius)
	atmosphere.visible = settings.hasAtmosphere
	if settings.hasAtmosphere:
		# Adjust atmosphere.
		atmosphere.mesh = orgAtmoMesh.duplicate(true)
		atmoMaterial = atmosphere.mesh.surface_get_material(0)
		atmosphere.mesh.size = Vector3(settings.radius*2.5, settings.radius*2.5, settings.radius*2.5)
		atmoMaterial.set_shader_param("planet_radius", settings.radius)
		atmoMaterial.set_shader_param("atmo_radius", settings.radius * settings.atmosphereThickness)
	
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, dir, settings.resolution, material)
		addTerrainFace(face)
	print(str(self) + ", " + name + ", took: " + str(OS.get_ticks_msec() - time_before) + "ms for generate()")


func addTerrainFace(var face: TerrainFace):
	terrain.add_child(face)


func setDoGenerate(var new: bool):
	generate()
