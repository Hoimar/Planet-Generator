tool
class_name PlanetSettings
extends Resource

export(int, 3, 9999) var resolution: int = 20 setget set_resolution
export(float) var radius: float = 100 setget set_radius
export(bool) var has_water = false setget set_has_water
export(Resource) var water_shader setget set_water_shader
export(bool) var has_atmosphere = true setget set_has_atmosphere
export(bool) var has_collisions = true setget set_has_collisions
export(bool) var has_clouds = false setget set_has_clouds
export(Resource) var cloud_shader setget set_cloud_shader
#export(float) var cloud_resolution = 1.0 setget set_cloud_resolution
export(float, 1, 10000) var atmosphere_thickness: float = 12 setget set_atmosphere_thickness
export(float, 0.0, 1.0) var atmosphere_density: float = 0.02 setget set_atmosphere_density
export(Resource) var shape_generator

var _planet: Spatial setget , get_planet
var shared_mutex := Mutex.new()   # Used for threads creating physics shapes.


func init(var _planet):
	self._planet = _planet
	shape_generator.init(_planet)
	if _planet.has_node("Clouds"):
		if !cloud_shader:
			cloud_shader = _planet.get_node("Clouds").mesh.material
		else:
			_planet.get_node("Clouds").mesh.material = cloud_shader
		#_planet.get_node("Clouds/Viewport").size = Vector2(600, 300) * cloud_resolution
		
		if !water_shader:
			water_shader = _planet.get_node("WaterSphere").mesh.material
		else:
			_planet.get_node("WaterSphere").mesh.material = water_shader


func set_cloud_shader(shader):
	if _planet:
		_planet.get_node("Clouds").mesh.material = shader
	cloud_shader = shader

func set_cloud_resolution(n):
	return
	#cloud_resolution = n
	#if _planet:
	#	_planet.get_node("Clouds/Viewport").size = Vector2(600, 300) * n

func set_has_clouds(n:bool):
	has_clouds = n
	on_settings_changed()

func on_settings_changed():
	if not _planet:
		return
	_planet.generate()


func set_resolution(var new: int):
	resolution = new
	on_settings_changed()


func set_radius(var new: float):
	radius = new
	on_settings_changed()

func set_water_shader(new):
	if _planet:
		_planet.get_node("WaterSphere").mesh.material = new
	water_shader = new

func set_has_water(var new: bool):
	has_water = new
	on_settings_changed()


func set_has_atmosphere(var new: bool):
	has_atmosphere = new
	on_settings_changed()


func set_atmosphere_thickness(var new: float):
	atmosphere_thickness = new
	on_settings_changed()


func set_atmosphere_density(var new: float):
	atmosphere_density = new
	on_settings_changed()
	

func set_has_collisions(var new: bool):
	has_collisions = new
	on_settings_changed()


func get_planet() -> Spatial:
	return _planet
