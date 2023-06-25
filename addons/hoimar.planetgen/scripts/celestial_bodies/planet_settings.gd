@tool
class_name PlanetSettings
extends Resource

@export_range(3, 9999) var resolution: int = 20: set = set_resolution
@export var radius: float = 100: set = set_radius
@export var has_water: bool = false: set = set_has_water
@export var has_atmosphere: bool = true: set = set_has_atmosphere
@export var has_collisions: bool = true: set = set_has_collisions
@export_range(1.0, 10000.0) var atmosphere_thickness: float = 1.15: set = set_atmosphere_thickness
@export_range(0.0, 1.0) var atmosphere_density: float = 0.1: set = set_atmosphere_density
@export var shape_generator: Resource

var _planet: Node3D: get = get_planet
var shared_mutex := Mutex.new()   # Used for threads creating physics shapes.


func init(_planet):
	self._planet = _planet
	shape_generator.init(_planet)


func on_settings_changed():
	if not _planet:
		return
	_planet.generate()


func set_resolution(new: int):
	resolution = new
	on_settings_changed()


func set_radius(new: float):
	radius = new
	on_settings_changed()


func set_has_water(new: bool):
	has_water = new
	on_settings_changed()


func set_has_atmosphere(new: bool):
	has_atmosphere = new
	on_settings_changed()


func set_atmosphere_thickness(new: float):
	atmosphere_thickness = new
	on_settings_changed()


func set_atmosphere_density(new: float):
	atmosphere_density = new
	on_settings_changed()
	

func set_has_collisions(new: bool):
	has_collisions = new
	on_settings_changed()


func get_planet() -> Node3D:
	return _planet
