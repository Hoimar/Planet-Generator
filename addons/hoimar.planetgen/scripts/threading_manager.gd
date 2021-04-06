class_name ThreadingManager
extends Node

const MAX_WAIT_TIME := 5.0

enum STATE {THREADS_RUNNING, IDLE, CLEANING_UP, FINISHED}

var _state: int = STATE.IDLE
var _thread_pool: Array   # Keep track of all spawned threads.
var _logger := Logger.get_for(self)


func can_generate() -> bool:
	return _state == STATE.IDLE


func get_number_of_threads() -> int:
	return _thread_pool.size()


func update_state():
	if _state == STATE.CLEANING_UP or _state == STATE.FINISHED:
		return
	elif _thread_pool.size() == 0:
		_state = STATE.IDLE
	else:
		_state = STATE.THREADS_RUNNING


func register_thread(var thread: Thread):
	_thread_pool.append(thread)
	update_state()


# Called deferred from TerrainPatch thread when it has finished.
func finish_thread(var thread: Thread):
	if thread and thread.is_active():
		thread.wait_to_finish()
	_thread_pool.erase(thread)
	update_state()


# Join all threads so they don't continue running when the window is closed.
func wait_for_all_threads(var block_thread: bool):
	if _state == STATE.CLEANING_UP or _state == STATE.FINISHED:
		return
	_state = STATE.CLEANING_UP
	if block_thread:
		finish_all_threads()
	else:
		var thread := Thread.new()
		var _unused = thread.start(self, "finish_all_threads")
		# TODO: Handle threads that are frozen / hung.


func finish_all_threads(var userdata = null):
	while _thread_pool.size() > 0:
		finish_thread(_thread_pool.front())
	_state = STATE.FINISHED
