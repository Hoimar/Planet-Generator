tool
class_name TerrainJob

# Class that takes care of building one patch of terrain from PatchData object.

const TERRAIN_PATCH_SCENE = preload("../../scenes/terrain/terrain_patch.tscn")

signal job_finished(job, result)

var _data: PatchData setget , get_data
var _is_aborted: bool setget abort, is_aborted


func _init(var data: PatchData):
	_data = data


func run():
	if handle_job_canceled():    # Check before running job.
		return
	# Build the patch of terrain.
	var patch: TerrainPatch = TERRAIN_PATCH_SCENE.instance()
	patch.build(_data)
	if handle_job_canceled():    # Check after running job.
		return
	else:
		finish_deferred(patch)   # Return results.


# Signal that this job is finished in a thread-safe way.
func finish_deferred(var patch: TerrainPatch):
	call_deferred("emit_signal", "job_finished", self, patch)


func handle_job_canceled() -> bool:
	if _is_aborted:
		finish_deferred(null)
	return _is_aborted


# "Setter" function used only to abort the job.
func abort(var b := true):
	_is_aborted = true


func is_aborted() -> bool:
	return _is_aborted


func get_data() -> PatchData:
	return _data
