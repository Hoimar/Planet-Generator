tool
class_name JobQueue

# Handles queueing terrain jobs and feeding them to a defined amount of
# worker threads, balancing the load.

const Const := preload("../constants.gd")
enum STATE {WORKING, IDLE, CLEANING_UP, CLEANED_UP}

signal finished

# Don't use all available CPU threads by default:
var _num_workers: int = max(1, OS.get_processor_count())
var _state: int = STATE.IDLE
var _state_mutex := Mutex.new()
var _queue := []
var _queue_mutex := Mutex.new()
var _worker_pool := []
var _last_worker := 0
var _logger := Logger.get_for(self)
var _feeder_thread := Thread.new()   # Takes care of keeping worker threads busy.


func _init():
	# Ensure we have at least one worker thread (shouldn't be needed though).
	for i in _num_workers:
		_worker_pool.append(WorkerThread.new())
	_feeder_thread.start(self, "_feeder_thread_function")


func _feeder_thread_function(userargs = null):
	while _state != STATE.CLEANING_UP:
		if _queue.empty():
			OS.delay_usec(Const.THREAD_DELAY)
		else:
			process_queue()


# Keeps worker threads busy by feeding them jobs.
# TODO: Feed all idle workers with available jobs instead of just one. Huge bottleneck!
func process_queue():
	if _queue.empty():
		return
	var job: TerrainJob = _queue.front()
	
	var job_accepted: bool
	for i in _num_workers:
		var worker: WorkerThread = _worker_pool[_last_worker % _num_workers]
		_last_worker += 1   # Simple load balancing.
		job_accepted = worker.set_job(job)
		if job_accepted:
			break
	
	if job_accepted:
		# Remove the job, it's being processed.
		_queue_mutex.lock()
		_queue.pop_front()
		_queue_mutex.unlock()
	update_state()


func is_working() -> bool:
	if _state == STATE.WORKING or _state == STATE.CLEANING_UP:
		return true
	else:
		return false


func get_number_of_jobs() -> int:
	return _queue.size()


func get_jobs_for(var planet: Planet) -> Array:
	var result := []
	for job in _queue:
		if job.get_data().settings.get_planet() == planet:
			result.append(job)
	return result


func update_state():
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	_state_mutex.lock()
	if _queue.empty():
		_state = STATE.IDLE
		call_deferred("emit_signal", "finished")   # Thread-safe.
	else:
		_state = STATE.WORKING
	_state_mutex.unlock()


func queue(var job: TerrainJob):
	if _state == STATE.CLEANING_UP:
		return
	_queue_mutex.lock()
	_queue.append(job)
	_queue_mutex.unlock()
	job.connect("job_finished", self, "on_job_finished", [], CONNECT_DEFERRED)
	update_state()


func on_job_finished(var job: TerrainJob, var patch: TerrainPatch):
	update_state()


# Clean up jobs and worker threads.
func clean_up():
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	_clean_jobs_and_workers()


func _clean_jobs_and_workers():
	# Update state and clear job queue.
	_state_mutex.lock()
	_state = STATE.CLEANING_UP
	_state_mutex.unlock()
	_queue_mutex.lock()
	_queue.clear()   # Simply free all jobs, we won't need their results.
	_queue_mutex.unlock()
	
	# Join all threads and clean pool.
	if _feeder_thread.is_active():
		_feeder_thread.wait_to_finish()
	for worker in _worker_pool:
		worker.set_running(false)
		if worker.is_active():
			worker.wait_to_finish()
	_worker_pool.clear()
	
	_state_mutex.lock()
	_state = STATE.CLEANED_UP
	_state_mutex.unlock()
