tool
class_name SolarSystem, "../resources/icons/solar-system.svg"
extends Node

var _all_planets: Array
var _logger := Logger.get_for(self)


func registerPlanet(var planet: Planet):
	_all_planets.append(planet)


func removePlanet(var planet: Planet):
	_all_planets.erase(planet)


# For debugging purposes.
func printNumOfActiveThreads():
	var num = 0
	for planet in _all_planets:
		for t in planet.terrain.threadingManager._threadPool:
			if t.is_active():
				num += 1
	_logger.debug("%s%s has %s active threads." % [name, str(self), str(num)])
