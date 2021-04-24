tool
class_name WorkerThread
extends Thread
# Represents a single worker thread that processes terrain jobs that are set by
# the job queue.

const Const := preload("../constants.gd")

var semaphore: Semaphore
var queue: Reference


func _init(var job_queue: Reference):
	self.queue = job_queue
	self.semaphore = job_queue.semaphore
	start(self, "work")


# Thread function.
func work(userdata = null):
	while true:
		semaphore.wait()   # Wait until we posted by queue.
		var job: TerrainJob = queue.fetch_job()
		if job:
			job.run()
		else:
			break   # Semaphore posted but no jobs queued: Worker should stop.
