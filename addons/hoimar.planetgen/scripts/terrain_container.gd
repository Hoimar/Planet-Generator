tool
class_name TerrainContainer
extends Spatial

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

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
	# Update every terrain face.
	for face in get_children():
		face.update(delta, _viewer_node.global_transform.origin)


# Generate terrain faces.
func generate(var settings: PlanetSettings, var material: Material):
	for child in get_children():
		child.queue_free()

	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, settings, dir, material)


func register_terrain_face(var face: TerrainFace):
	threading_manager.register_thread(face.thread)


# Called deferred from TerrainFace thread when it has finished.
func finish_terrain_face(var face: TerrainFace):
	threading_manager.finish_thread(face.thread)
	if !face.parent_face:
		# This is a top-level face, make it visible ourselves.
		add_child(face)
		face.set_visible(true)
