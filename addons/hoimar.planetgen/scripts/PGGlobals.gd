# Global settings for Planet Generator.
tool
extends Node

const MOUSE_SENSITIVITY: float = 0.05

var wireframe: bool = false setget set_wireframe       # Wireframe mode for newly (?) generated meshes.
var coloredFaces: bool   # Colors patches of terrain randomly.
var benchmarkMode: bool   # re-generates planets even if there are still active threads.
var prev_auto_accept_quit: bool
var is_quitting: bool
var solarSystems: Array = []


func _enter_tree():
	prev_auto_accept_quit = ProjectSettings.get_setting("application/config/auto_accept_quit")
	get_tree().set_auto_accept_quit(false)   # Don't just quit the program.


func _exit_tree():
	get_tree().set_auto_accept_quit(prev_auto_accept_quit)


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		# User quits program: Clean up solar system.
		is_quitting = true
		get_tree().quit()


func cleanUpSolarSystems(var block_thread: bool):
	for sys in solarSystems:
		sys.cleanUpPlanets(block_thread)


func registerSolarSystem(var sys: SolarSystem):
	solarSystems.append(sys)


func unregisterSolarSystem(var sys: SolarSystem):
	solarSystems.erase(sys)


func set_wireframe(new):
	wireframe = new
	VisualServer.set_debug_generate_wireframes(new)
	if new:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME)
	else:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_DISABLED);
