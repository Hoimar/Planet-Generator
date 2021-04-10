tool
class_name TerrainJob

# Class that takes care of building one patch of terrain from PatchData object.

const TERRAIN_PATCH_SCENE = preload("../../scenes/terrain/terrain_patch.tscn")

signal job_finished(job, result)

var _data: PatchData


func _init(var data: PatchData):
	_data = data


# Called when the node enters the scene tree for the first time.
func run():
	var patch: TerrainPatch = TERRAIN_PATCH_SCENE.instance()
	patch.build(_data)
	emit_signal("job_finished", self, patch)
