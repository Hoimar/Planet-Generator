tool
class_name SolarSystem, "../../resources/icons/solar_system.svg"
extends Spatial

var _all_planets: Array
var _logger := Logger.get_for(self)


func register_planet(var planet: Planet):
	_all_planets.append(planet)


func unregister_planet(var planet: Planet):
	_all_planets.erase(planet)


func _enter_tree():
	PGGlobals.register_solar_system(self)


func _exit_tree():
	PGGlobals.unregister_solar_system(self)
