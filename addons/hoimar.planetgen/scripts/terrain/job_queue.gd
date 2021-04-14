tool
class_name JobQueue

# Handles queueing terrain jobs and feeding them to a defined amount of
# worker threads, balancing the load.

const MAX_WAIT_TIME := 5.0

enum STATE {WORKING, IDLE, CLEANING_UP, CLEANED_UP}

# Don't use all available CPU threads by default:
var _num_workers := OS.get_processor_count() - 1
var _state: int = STATE.IDLE
var _queue := []
var _worker_pool := []
var _last_worker: int
var _logger := Logger.get_for(self)


func _init():
	for i in _num_workers:
		_worker_pool.append(WorkerThread.new())
	_last_worker = 0


# Handles feeding worker threads with jobs.
# TODO: Feed workers in a separate thread, so it's not only called every frame?
# TODO: Feed all idle workers with available jobs instead of just one. Huge bottleneck!
func process_queue():
	if _queue.empty():
		return
	var job_accepted: bool
	var job: TerrainJob = _queue.front()
	for i in _num_workers:
		var worker: WorkerThread = _worker_pool[_last_worker % _num_workers]
		_last_worker += 1   # Simple load balancing.
		job_accepted = worker.set_job(job)
		if job_accepted:
			break
	if job_accepted:
		# Remove the job, it's being processed.
		_queue.pop_front()
	update_state()


func is_working() -> bool:
	match _state:
		STATE.WORKING, STATE.CLEANING_UP:
			return true
		_:
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
	match _state:
		STATE.CLEANING_UP, STATE.CLEANED_UP:
			return
	if _queue.empty():
		_state = STATE.IDLE
	else:
		_state = STATE.WORKING


func queue(var job: TerrainJob):
	if _state == STATE.CLEANING_UP:
		return
	_queue.append(job)
	job.connect("job_finished", self, "on_job_finished")
	update_state()


func on_job_finished(var job: TerrainJob, var patch: TerrainPatch):
	_queue.erase(job)
	update_state()


# Clean up jobs and worker threads.
func clean_up(var block_thread: bool):
	if _state == STATE.CLEANING_UP or _state == STATE.CLEANED_UP:
		return
	if block_thread:
		clean_jobs_and_workers()
	else:
		var thread := Thread.new()
		var _unused = thread.start(self, "clean_jobs_and_workers")


func clean_jobs_and_workers(var userdata = null):
	_state = STATE.CLEANING_UP
	_queue.clear()   # Simply free all jobs, we won't need their results.
	# Join all threads to finish.
	for worker in _worker_pool:
		worker.set_running(false)
		worker.wait_to_finish()
	_worker_pool.clear()
	_state = STATE.CLEANED_UP
