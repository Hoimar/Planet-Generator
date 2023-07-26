@tool
@icon("../../resources/icons/solar_system.svg")
class_name SolarSystem
extends Node3D

var _all_planets: Array
var _logger := Logger.get_for(self)


func register_planet(planet: Planet):
	_all_planets.append(planet)


func unregister_planet(planet: Planet):
	_all_planets.erase(planet)


func _enter_tree():
	PGGlobals.register_solar_system(self)


func _exit_tree():
	PGGlobals.unregister_solar_system(self)
