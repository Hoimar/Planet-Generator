tool
class_name SolarSystem, "../resources/icons/solar_system.svg"
extends Node

var _all_planets: Array
var _logger := Logger.get_for(self)


func register_planet(var planet: Planet):
	_all_planets.append(planet)


func unregister_planet(var planet: Planet):
	_all_planets.erase(planet)


# For debugging purposes.
func print_num_of_active_threads():
	var num = 0
	for planet in _all_planets:
		for t in planet.terrain.threading_manager._thread_pool:
			if t.is_active():
				num += 1
	_logger.debug("%s%s has %s active threads." % [name, str(self), str(num)])
