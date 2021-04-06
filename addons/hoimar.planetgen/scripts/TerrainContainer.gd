tool
class_name TerrainContainer
extends Spatial

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

var threadingManager := ThreadingManager.new()
var quadTrees: Array
var _viewer_node: Spatial   # Specify from where this terrain is viewed.
var _logger := Logger.get_for(self)


func _ready():
	for _i in range(0, DIRECTIONS.size()):
		quadTrees.append(QuadTree.new())
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


func registerTerrainFace(var face: TerrainFace):
	threadingManager.registerThread(face.thread)


# Called deferred from TerrainFace thread when it has finished.
func finishTerrainFace(var face: TerrainFace):
	threadingManager.finishThread(face.thread)
	if !face.parentFace:
		# This is a top-level face, make it visible ourselves.
		add_child(face)
		face.set_visible(true)
