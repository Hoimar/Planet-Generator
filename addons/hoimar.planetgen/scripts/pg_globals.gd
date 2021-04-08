# Global settings for Planet Generator.
tool
extends Node

const MOUSE_SENSITIVITY: float = 0.05

var wireframe: bool = false setget set_wireframe       # Wireframe mode for newly (?) generated meshes.
var colored_patches: bool   # Colors patches of terrain randomly.
var benchmark_mode: bool   # re-generates planets even if there are still active threads.
var prev_auto_accept_quit: bool
var is_quitting: bool
var solar_systems: Array = []


func _enter_tree():
	prev_auto_accept_quit = ProjectSettings.get_setting("application/config/auto_accept_quit")
	get_tree().set_auto_accept_quit(false)   # Don't just quit the program.


func _exit_tree():
	get_tree().set_auto_accept_quit(prev_auto_accept_quit)


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		is_quitting = true
		get_tree().quit()


func clean_up_solar_systems(var block_thread: bool):
	# TODO: Finish all threads when exiting / leaving.
	for sys in solar_systems:
		sys.cleanUpPlanets(block_thread)


func register_solar_system(var sys: SolarSystem):
	solar_systems.append(sys)


func unregister_solar_system(var sys: SolarSystem):
	solar_systems.erase(sys)


func set_wireframe(new):
	wireframe = new
	VisualServer.set_debug_generate_wireframes(new)
	if new:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME)
	else:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_DISABLED);
