tool
class_name TerrainJobPool


const MAX_WAIT_TIME := 5.0
const WORKER_THREADS := 12

enum STATE {WORKING, IDLE, CLEANING_UP, CLEANED_UP}

var _state: int = STATE.IDLE
var _job_queue := Array()
var _thread_pool := Array()
var _logger := Logger.get_for(self)


func _init():
	_thread_pool.resize(WORKER_THREADS)


func process_queue():
	if _job_queue.empty():
		return
	var job: TerrainJob = _job_queue.front()
	job.run()
	update_state()


func is_working() -> bool:
	match _state:
		STATE.WORKING, STATE.CLEANING_UP:
			return true
		_:
			return false


func get_number_of_jobs() -> int:
	return _job_queue.size()


func update_state():
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	elif get_number_of_jobs() == 0:
		_state = STATE.IDLE
	else:
		_state = STATE.WORKING


func queue(var job: TerrainJob):
	if _state == STATE.CLEANING_UP:
		return
	_job_queue.append(job)
	job.connect("job_finished", self, "on_job_finished")
	update_state()


# Called deferred from TerrainPatch thread when it has finished.
func on_job_finished(var job: TerrainJob, var patch: TerrainPatch):
	_job_queue.erase(job)
	update_state()


# Make all jobs finish so we don't have unexpected behavior when they finish.
func clean_up(var block_thread: bool):
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	_state = STATE.CLEANING_UP
	if block_thread:
		finish_all_jobs()
	else:
		var thread := Thread.new()
		var _unused = thread.start(self, "finish_all_jobs")
		# TODO: Handle threads that are frozen / hung.


func finish_all_jobs(var userdata = null):
	while _job_queue.size() > 0:
		process_queue()
	_state = STATE.CLEANED_UP
