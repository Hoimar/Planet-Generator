tool
class_name Planet, "../resources/icons/planet.svg"
extends Spatial

const WATERMATERIAL: Material = preload("../resources/materials/WaterMaterial.tres")

export(bool) var doGenerate: bool = false setget setDoGenerate
export(Resource) var settings
export(Material) var material: Material
export(NodePath) var solarSystemPath: NodePath
export(NodePath) var sunPath: NodePath
var orgAtmoMesh: Mesh
var orgWaterMesh: Mesh
var atmoMaterial: ShaderMaterial
var sun: Spatial
var solarSystem: Node
var _logger := Logger.get_for(self)
onready var terrain: TerrainContainer = $terrain
onready var waterSphere: MeshInstance = $waterSphere
onready var atmosphere = $atmosphere



func _ready():
	if !orgAtmoMesh:
		orgAtmoMesh = atmosphere.mesh
	if !orgWaterMesh:
		orgWaterMesh = waterSphere.mesh
	if sunPath:
		sun = get_node(sunPath)
	generate()


func _process(_delta):
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
	
	_logger.debug("%s%s started generating after %sms." % [name, str(self), str(OS.get_ticks_msec() - time_before)])


func areConditionsMet() -> bool:
	if not settings or not material:
		_logger.error("Settings or material is not set, can't generate %s%s." %
			[name, str(self)])
		return false
	if not (terrain.threadingManager.canGenerate() or PGGlobals.benchmarkMode):
		_logger.error("Can't generate \"%s%s\", it still has %s generator threads running." %
			[name, str(self), terrain.threadingManager.getNumberOfThreads()])
		return false
	return true


func setDoGenerate(_new):
	generate()


func cleanUpThreads(var block_thread: bool):
	terrain.threadingManager.waitForAllThreads(block_thread)


func _enter_tree():
	if solarSystemPath:
		solarSystem = get_node(solarSystemPath)
	elif get_parent().has_method("registerPlanet"):   # TODO: Properly find if parent is SolarSystem.
		solarSystemPath = ".."
		solarSystem = get_parent()
	if solarSystem:
		solarSystem.registerPlanet(self)


func _exit_tree():
	if PGGlobals.is_quitting:
		cleanUpThreads(true)
	else:
		cleanUpThreads(false)
		if solarSystem:
			solarSystem.removePlanet(self)


func _get_configuration_warning() -> String:
	if settings and settings.hasAtmosphere and !sunPath:
		return "Node path to sun is not set in 'Sun Path' (you can use any Spatial for that)."
	if !solarSystemPath:
		return "Node path to the solar system node is not set in 'Solar System Path'."
	return _get_common_config_warning()


# Shared configuration warnings between this class and subclasses.
func _get_common_config_warning() -> String:
	if not settings:
		return "Missing a 'PlanetSettings' resource in 'Settings'."
	if not material:
		return "Missing a 'Material' resource in 'Material'."
	return ""
