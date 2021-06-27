tool
class_name Planet, "../../resources/icons/planet.svg"
extends Spatial
# Class for a planet taking care of terrain, atmosphere, water etc.

export(bool) var do_generate: bool = false setget set_do_generate
export(Resource) var settings
export(Material) var material: Material
export(NodePath) var solar_system_path: NodePath
export(NodePath) var sun_path: NodePath
var _org_water_mesh: Mesh
var _solar_system: Node
var _logger := Logger.get_for(self)
onready var _terrain: TerrainManager = $TerrainManager
onready var _atmosphere = $Atmosphere
onready var _water_sphere: MeshInstance = $WaterSphere


func _ready():
	if not _org_water_mesh:
		_org_water_mesh = _water_sphere.mesh
	generate()


# Generate whole planet.
func generate():
	if not are_conditions_met():
		return
	var time_before = OS.get_ticks_msec()
	settings.init(self)
	_terrain.generate(settings, material)
	
	# Adjust water.
	_water_sphere.visible = settings.has_water
	if settings.has_water:
		var material = _org_water_mesh.surface_get_material(0).duplicate()
		_water_sphere.mesh = _org_water_mesh.duplicate()
		_water_sphere.mesh.radius = settings.radius
		_water_sphere.mesh.height = settings.radius*2
		_water_sphere.mesh.surface_set_material(0, material)
		material.set_shader_param("planet_radius", settings.radius)
	
	# Adjust atmosphere.
	_atmosphere.visible = settings.has_atmosphere
	if settings.has_atmosphere:
		_atmosphere.planet_radius = settings.radius
		_atmosphere.atmosphere_height = settings.atmosphere_thickness
		_atmosphere.atmosphere_density = settings.atmosphere_density
		_atmosphere.set_sun_path("../" + sun_path)
		
	_logger.debug("%s%s started generating after %sms." % [name, str(self), str(OS.get_ticks_msec() - time_before)])


func are_conditions_met() -> bool:
	if not settings or not material:
		_logger.warn("Settings or material not set, can't generate %s%s." %
			[name, str(self)])
		return false
	if not _terrain:
		_logger.warn("Terrain %s%s for not yet initialized." % [name, str(self)])
		return false
	var jobs: Array = PGGlobals.job_queue.get_jobs_for(self)
	if !jobs.empty() and not PGGlobals.benchmark_mode:
		_logger.warn("Waiting for %d jobs to finish before generating \"%s%s\"." %
				[jobs.size(), name, str(self)])
		return false
	return true


func set_do_generate(_new):
	generate()


func _enter_tree():
	if solar_system_path:
		_solar_system = get_node(solar_system_path)
	elif get_parent().has_method("register_planet"):   # TODO: Properly find if parent is _solar_system.
		solar_system_path = ".."
		_solar_system = get_parent()
	if _solar_system:
		_solar_system.register_planet(self)


func _exit_tree():
	if _solar_system:
		_solar_system.unregister_planet(self)


func _get_configuration_warning() -> String:
	if settings and settings.has_atmosphere and not sun_path:
		return "Node path to sun node is not set in 'Sun Path'."
	if not solar_system_path:
		return "Node path to the solar system node is not set in 'Solar System Path'."
	return _get_common_config_warning()


# Shared configuration warnings between this class and subclasses.
func _get_common_config_warning() -> String:
	if not settings:
		return "Missing a 'PlanetSettings' resource in 'Settings'."
	if not material:
		return "Missing a 'Material' resource in 'Material'."
	return ""
