tool
class_name Planet
extends Spatial

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
const WATERMATERIAL: Material = preload("res://resources/WaterMaterial.tres")

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings
export(Material) var material: Material
export(NodePath) var sunPath: NodePath

var orgAtmoMesh: Mesh
var orgWaterMesh: Mesh
var atmoMaterial: ShaderMaterial

onready var terrain: TerrainContainer = $terrain
onready var waterSphere: MeshInstance = $waterSphere
onready var atmosphere = $atmosphere
onready var sun


func _ready():
	if !orgAtmoMesh:
		orgAtmoMesh = atmosphere.mesh
	if !orgWaterMesh:
		orgWaterMesh = waterSphere.mesh
	if sunPath:
		sun = get_node(sunPath)
	generate()


func _enter_tree():
	Global.registerPlanet(self)


func _exit_tree():
	Global.removePlanet(self)


func _physics_process(_delta):
	var camera = get_viewport().get_camera()
	if camera and settings.hasAtmosphere:
		# Update atmosphere shader.
		var distance: float = global_transform.origin.distance_to(camera.global_transform.origin)
		var minScale: float = 1.0
		var maxScale: float = 1.06
		var scale: float = range_lerp(distance, settings.radius*1.75, settings.radius*5,
									  minScale, maxScale)
		scale = max(minScale, min(scale, maxScale))
		if atmoMaterial:
			atmoMaterial.set_shader_param("planet_radius", settings.radius*scale)
			atmoMaterial.set_shader_param("atmo_radius", settings.radius*settings.atmosphereThickness*scale)
		if sun and self != sun:
			var atmoDirection = global_transform.origin - (sun.global_transform.origin - global_transform.origin)
			atmosphere.look_at_from_position(global_transform.origin, atmoDirection, transform.basis.y)


# Generate whole planet.
func generate():
	var time_before = OS.get_ticks_msec()
	if not areConditionsMet():
		return
	settings.init(self)
	terrain.generate(settings, material)

	# Adjust water.
	waterSphere.visible = settings.hasWater
	if settings.hasWater:
		waterSphere.mesh = orgWaterMesh.duplicate(true)
		waterSphere.mesh.radius = settings.radius
		waterSphere.mesh.height = settings.radius*2
		var waterMaterial = waterSphere.mesh.surface_get_material(0)
		waterMaterial.set_shader_param("planet_radius", settings.radius)

	# Adjust atmosphere.
	atmosphere.visible = settings.hasAtmosphere
	if settings.hasAtmosphere:
		atmosphere.mesh = orgAtmoMesh.duplicate(true)
		atmosphere.mesh.size = Vector3(settings.radius*2.5, settings.radius*2.5, settings.radius*2.5)
		atmoMaterial = atmosphere.mesh.surface_get_material(0)
		atmoMaterial.set_shader_param("planet_radius", settings.radius)
		atmoMaterial.set_shader_param("atmo_radius", settings.radius * settings.atmosphereThickness)

	print("Planet: Debug: \"" + name + str(self) + "\" took " + str(OS.get_ticks_msec() - time_before) + "ms to generate().")


func areConditionsMet() -> bool:
	if not settings or not material:
		print("Planet: Warning: Can't generate, settings or material for ", self, " is null.")
		return false
	if not (terrain.threadingManager.canGenerate() or Global.benchmarkMode):
		print("Planet: Error: Can't generate \"" + name + "\", it still has ",
			  terrain.threadingManager.getNumberOfThreads(),
			  " generator threads running.")
		return false
	return true


func setDoGenerate(_new):
	generate()


func cleanUpThreads():
	terrain.threadingManager.waitForAllThreads()
