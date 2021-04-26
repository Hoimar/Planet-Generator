tool
class_name PlanetSettings
extends Resource

export(int, 3, 9999) var resolution: int = 20 setget set_resolution
export(float) var radius: float = 100 setget set_radius
export(bool) var has_water = false setget set_has_water
export(bool) var has_atmosphere = true setget set_has_atmosphere
export(bool) var has_collisions = true setget set_has_collisions
export(float, 1, 10000) var atmosphere_thickness: float = 1.15 setget set_atmosphere_thickness
export(float, 0.0, 1.0) var atmosphere_density: float = 0.1 setget set_atmosphere_density
export(Resource) var shape_generator

var _planet: Spatial setget , get_planet
var shared_mutex := Mutex.new()   # Used for threads creating physics shapes.


func init(var _planet):
	self._planet = _planet
	shape_generator.init(_planet)


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
