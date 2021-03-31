tool
extends Node

const MOUSE_SENSITIVITY: float = 0.05

var _allPlanets: Array

var coloredFaces: bool = false
var wireframe: bool = false
var benchmarkMode: bool = false


func _enter_tree():
	get_tree().set_auto_accept_quit(false)   # Don't just quit the program.


func registerPlanet(var planet: Planet):
	_allPlanets.append(planet)


func removePlanet(var planet: Planet):
	var idx: int = _allPlanets.find(planet)
	_allPlanets.remove(idx)


func cleanUpBeforeQuit():
	# Let all current threads finish.
	for planet in _allPlanets:
		planet.cleanUpThreads()
	get_tree().quit()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# User quits program.
		cleanUpBeforeQuit()


# For debugging purposes.
func printNumOfActiveThreads():
	var num = 0
	for planet in _allPlanets:
		for t in planet.terrain.threadingManager.threadPool:
			if t.is_active():
				num += 1
	print(num)
