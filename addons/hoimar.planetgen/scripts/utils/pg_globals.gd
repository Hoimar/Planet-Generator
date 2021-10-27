# Global settings for Planet Generator.
tool
extends Node

const Const := preload("../constants.gd")

var wireframe: bool = false setget set_wireframe       # Wireframe mode for newly (?) generated meshes.
var colored_patches: bool   # Colors patches of terrain randomly.
var benchmark_mode: bool   # re-generates planets even if there are still active threads.
var solar_systems: Array = []
var job_queue := JobQueue.new()   # Global queue for TerrainJobs.


func _ready():
	if Const.THREADS_ENABLED:
		set_process(false)   # Otherwise, process queue in single thread.


func _exit_tree():
	job_queue.clean_up()


func queue_terrain_patch(var data: PatchData) -> TerrainJob:
	var job := TerrainJob.new(data)
	job_queue.queue(job)
	return job


func register_solar_system(var sys: Node):
	solar_systems.append(sys)


func unregister_solar_system(var sys: Node):
	solar_systems.erase(sys)


func set_wireframe(var value: bool):
	wireframe = value
	VisualServer.set_debug_generate_wireframes(value)
	if value:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME)
	else:
		get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_DISABLED);


func _process(delta):
	job_queue.process_queue_without_threads()


func _input(event):
	if Engine.editor_hint:
		return
	if Input.is_action_just_pressed("toggle_mouse_capture"):
			if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
				Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
			else:
				Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
