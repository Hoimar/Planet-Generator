tool
class_name WorkerThread
extends Thread

var _running := true setget set_running
var _is_sleeping: bool = true
var _job: TerrainJob setget set_job


func _init():
	start(self, "work")


# Thread function.
func work(userdata = null):
	while _running:
		if _is_sleeping:
			OS.delay_msec(10)   # Sleep for a while to not make this a busy loop.
		else:   # We have a new job.
			_job.run()
			_is_sleeping = true


# Tries setting a new job, returns true if successful, false when busy.
func set_job(var new: TerrainJob) -> bool:
	if _is_sleeping:
		# Set new job and signal it to the thread.
		_job = new
		_is_sleeping = false
		return true
	else:
		return false


func set_running(var new: bool):
	_running = new
