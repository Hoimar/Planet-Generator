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
var job_queue := JobQueue.new()   # Global queue for TerrainJobs.


func _enter_tree():
	prev_auto_accept_quit = ProjectSettings.get_setting("application/config/auto_accept_quit")
	get_tree().set_auto_accept_quit(false)   # Don't just quit the program.


func _exit_tree():
	clean_up(true)
	get_tree().set_auto_accept_quit(prev_auto_accept_quit)


func _process(delta):
	job_queue.process_queue()


func _notification(what):
	if what == MainLoop.NOTIFICATION_WM_QUIT_REQUEST:
		is_quitting = true
		get_tree().quit()


func queue_terrain_patch(var data: PatchData) -> TerrainJob:
	var job := TerrainJob.new(data)
	job_queue.queue(job)
	return job


func clean_up(var block_thread: bool):
	# TODO: Finish all threads when exiting / leaving.
	job_queue.clean_up(block_thread)


func register_solar_system(var sys: Node):
	solar_systems.append(sys)


func unregister_solar_system(var sys: Node):
	solar_systems.erase(sys)


func set_wireframe(new):
	wireframe = new
	VisualServer.set_debug_generate_wireframes(new)
	if new:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME)
	else:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_DISABLED);
