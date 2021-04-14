tool
class_name CubeQuadTree

# Represents six quadtrees on a cube with one for each side.

const Const := preload("../constants.gd")

var _face_quadtrees: Dictionary   # Maps a cube face normal to a quadtree instance.


func _init(var terrain_manager):
	for dir in Const.DIRECTIONS:
		_face_quadtrees[dir] = QuadNode.new(null, dir, terrain_manager)


func set_viewer(var viewer: Spatial):
	for qt in _face_quadtrees.values():
		qt.set_viewer(viewer)


func get_num_children() -> int:
	var result: int
	for qt in _face_quadtrees:
		result += qt.get_num_children()
	return result
