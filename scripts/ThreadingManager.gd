class_name ThreadingManager

enum STATE {THREADS_RUNNING, IDLE}

var state: int = STATE.IDLE

var threadPool: Array   # Keep track of all spawned threads.


func canGenerate() -> bool:
	return state == STATE.IDLE


func getNumberOfThreads() -> int:
	return threadPool.size()


func updateState():
	if threadPool.size() == 0:
		state = STATE.IDLE
	else:
		state = STATE.THREADS_RUNNING


func registerThread(var thread: Thread):
	threadPool.append(thread)
	updateState()


# Called deferred from TerrainFace thread when it has finished.
func finishThread(var thread: Thread):
	if thread and thread.is_active():
		thread.wait_to_finish()
	threadPool.erase(thread)
	updateState()


# Join all threads so they don't continue running when the window is closed.
func waitForAllThreads():
	while threadPool.size() > 0:
		finishThread(threadPool.front())
