tool
class_name JobQueue

# Handles queueing terrain jobs and feeding them to a defined amount of
# worker threads, balancing the load.

const Const := preload("../constants.gd")
enum STATE {WORKING, IDLE, CLEANING_UP, CLEANED_UP}

signal all_finished

# Make sure to have at least one worker thread:
var _num_workers: int = max(1, OS.get_processor_count())
var _state: int = STATE.IDLE
var _state_mutex := Mutex.new()
var queued_jobs := []   # Jobs that have been queued for processing.
var queue_mutex := Mutex.new()
var processing_jobs := []   # Jobs that are currently being processed.
var _worker_pool := []
var _logger := Logger.get_for(self)
var semaphore:= Semaphore.new()


func _init():
	for i in _num_workers:
		_worker_pool.append(WorkerThread.new(self))


func is_working() -> bool:
	if _state == STATE.WORKING or _state == STATE.CLEANING_UP:
		return true
	else:
		return false


# Return total number of currently queued and processed jobs.
func get_number_of_jobs() -> int:
	return queued_jobs.size() + processing_jobs.size()


func get_jobs_for(var planet: Planet) -> Array:
	var result := []
	queue_mutex.lock()   # We don't want any surprises while reading.
	for job in queued_jobs:
		if job.get_data().settings.get_planet() == planet:
			result.append(job)
	for job in processing_jobs:
		if job.get_data().settings.get_planet() == planet:
			result.append(job)
	queue_mutex.unlock()
	return result


func update_state():
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	_state_mutex.lock()
	if queued_jobs.empty() and processing_jobs.empty():
		_state = STATE.IDLE
		call_deferred("emit_signal", "all_finished")   # Thread-safe.
	else:
		_state = STATE.WORKING
	_state_mutex.unlock()


# Add a new job to the queue.
func queue(var job: TerrainJob):
	if _state == STATE.CLEANING_UP:
		return
	queue_mutex.lock()
	queued_jobs.append(job)
	queue_mutex.unlock()
	job.connect("job_finished", self, "on_job_finished")
	semaphore.post()   # The next free worker thread will pick it up.
	update_state()


# Pop and return next job from the queue.
func fetch_job() -> TerrainJob:
	if queued_jobs.empty():
		return null   # May happen while cleaning up.
	var job: TerrainJob
	queue_mutex.lock()
	job = queued_jobs.pop_front()
	processing_jobs.append(job)
	queue_mutex.unlock()
	update_state()
	return job


func on_job_finished(var job: TerrainJob, var patch: TerrainPatch):
	queue_mutex.lock()
	processing_jobs.erase(job)
	queue_mutex.unlock()
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
	queue_mutex.lock()
	queued_jobs.clear()   # Simply free all jobs, we won't need their results.
	queue_mutex.unlock()
	
	yield(self, "all_finished")
	# Join all threads and clean pool.
	for worker in _num_workers:
		semaphore.post()   # One last cycle to let worker finish.
	while !_worker_pool.empty():
		var worker: WorkerThread = _worker_pool.pop_front()
		if worker.is_active():
			worker.wait_to_finish()
	
	_state = STATE.CLEANED_UP
