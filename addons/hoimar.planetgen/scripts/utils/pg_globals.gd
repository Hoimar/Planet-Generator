@tool
# Global settings for Planet Generator.
extends Node

const Const := preload("../constants.gd")

var wireframe: bool = false: set = set_wireframe
var colored_patches: bool   # Colors patches of terrain randomly.
var benchmark_mode: bool   # re-generates planets even if there are still active threads.
var solar_systems: Array = []
var job_queue := JobQueue.new()   # Global queue for TerrainJobs.
var speed_scale: float = 0.001


func _ready():
	if Const.THREADS_ENABLED:
		set_process(false)   # Otherwise, process queue in single thread.


func _exit_tree():
	job_queue.clean_up()


func queue_terrain_patch(data: PatchData) -> TerrainJob:
	var job := TerrainJob.new(data)
	job_queue.queue(job)
	return job


func register_solar_system(sys: Node):
	solar_systems.append(sys)


func unregister_solar_system(sys: Node):
	solar_systems.erase(sys)


func set_wireframe(value: bool):
	wireframe = value
	RenderingServer.set_debug_generate_wireframes(value)
	if value:
		get_viewport().set_debug_draw(SubViewport.DEBUG_DRAW_WIREFRAME)
	else:
		get_viewport().set_debug_draw(SubViewport.DEBUG_DRAW_DISABLED);


func _process(delta):
	job_queue.process_queue_without_threads()


func _input(event):
	if Engine.is_editor_hint():
		return
	if Input.is_action_just_pressed("toggle_mouse_capture"):
			if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
			else:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
