class_name ThreadingManager
extends Node

const MAX_WAIT_TIME := 5.0

enum STATE {THREADS_RUNNING, IDLE, CLEANING_UP, FINISHED}

var _state: int = STATE.IDLE
var _threadPool: Array   # Keep track of all spawned threads.
var _logger := Logger.get_for(self)

func canGenerate() -> bool:
	return _state == STATE.IDLE


func getNumberOfThreads() -> int:
	return _threadPool.size()


func updateState():
	if _state == STATE.CLEANING_UP or _state == STATE.FINISHED:
		return
	elif _threadPool.size() == 0:
		_state = STATE.IDLE
	else:
		_state = STATE.THREADS_RUNNING


func registerThread(var thread: Thread):
	_threadPool.append(thread)
	updateState()


# Called deferred from TerrainFace thread when it has finished.
func finishThread(var thread: Thread):
	if thread and thread.is_active():
		thread.wait_to_finish()
	_threadPool.erase(thread)
	updateState()


# Join all threads so they don't continue running when the window is closed.
func waitForAllThreads(var block_thread: bool):
	if _state == STATE.CLEANING_UP or _state == STATE.FINISHED:
		return
	_state = STATE.CLEANING_UP
	if block_thread:
		finishAllThreads()
	else:
		var thread := Thread.new()
		var _unused = thread.start(self, "finishAllThreads")
		# TODO: Handle threads that are frozen / hang.
		#if thread.is_active():
		#	print("ThreadingManager: Warning: Couldn't finish all generator threads.")


func finishAllThreads(var userdata = null):
	while _threadPool.size() > 0:
		finishThread(_threadPool.front())
	_state = STATE.FINISHED
