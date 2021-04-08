tool
class_name TerrainContainer
extends Spatial

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]
const TERRAIN_PATCH_SCENE = preload("../scenes/terrain_patch.tscn")

var threading_manager := ThreadingManager.new()
var quadtrees: Array
var _viewer_node: Spatial   # Specify from where this terrain is viewed.
var _logger := Logger.get_for(self)


func _ready():
	for _i in DIRECTIONS.size():
		quadtrees.append(QuadTree.new())
	if !_viewer_node:   # Was it already initialized from elsewhere?
		_viewer_node = get_viewport().get_camera()


func _process(delta):
	if !_viewer_node:
		return
	# Update every terrain patch.
	for patch in get_children():
		patch.update(delta, _viewer_node.global_transform.origin)


# Generate terrain patches.
func generate(var settings: PlanetSettings, var material: Material):
	for child in get_children():
		child.queue_free()

	for dir in DIRECTIONS:
		var patch: TerrainPatch = TERRAIN_PATCH_SCENE.instance()
		patch.init(self, settings, dir, material)


func register_terrain_patch(var patch):
	threading_manager.register_thread(patch.thread)


# Called deferred from TerrainPatch thread when it has finished.
func finish_terrain_patch(var patch):
	threading_manager.finish_thread(patch.thread)
	if !patch.parent_patch:
		# This is a top-level patch, make it visible ourselves.
		add_child(patch)
		patch.set_visible(true)
