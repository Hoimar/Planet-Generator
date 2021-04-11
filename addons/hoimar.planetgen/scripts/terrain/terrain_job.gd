tool
class_name TerrainJob

# Class that takes care of building one patch of terrain from PatchData object.

const TERRAIN_PATCH_SCENE = preload("../../scenes/terrain/terrain_patch.tscn")

signal job_finished(job, result)

var _data: PatchData
var _is_aborted: bool setget abort, is_aborted
var mutex := Mutex.new()


func _init(var data: PatchData):
	_data = data


func run():
	if _is_aborted:   # Check before running job.
		emit_signal("job_finished", self, null)
		return
	var patch: TerrainPatch = TERRAIN_PATCH_SCENE.instance()
	patch.build(_data)
	if _is_aborted:   # Check after running job.
		emit_signal("job_finished", self, null)
		return
	else:
		emit_signal("job_finished", self, patch)


# "Setter" function used only to abort the job.
func abort(var b := true):
	mutex.lock()
	_is_aborted = true
	mutex.unlock()


func is_aborted() -> bool:
	return _is_aborted
