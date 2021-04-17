tool
class_name WorkerThread
extends Thread
# Represents a single worker thread that processes terrain jobs that are set by
# the job queue.

const Const := preload("../constants.gd")

var _running := true setget set_running
var _is_sleeping: bool = true
var _job: TerrainJob setget set_job
var _mutex := Mutex.new()


func _init():
	start(self, "work")


# Thread function.
func work(userdata = null):
	while _running:
		if _is_sleeping:
			OS.delay_usec(Const.THREAD_DELAY)   # Sleep for a while to not make this a busy loop.
		else:   # We have a new job.
			_job.run()
			_mutex.lock()
			_is_sleeping = true
			_mutex.unlock()


# Called from another thread. Returns true if successful, false when busy.
func set_job(var new: TerrainJob) -> bool:
	if _is_sleeping:
		# Set new job and signal it to the thread.
		_job = new
		_mutex.lock()
		_is_sleeping = false
		_mutex.unlock()
		return true
	else:
		return false


func set_running(var new: bool):
	_running = new
