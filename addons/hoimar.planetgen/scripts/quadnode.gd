tool
class_name QuadNode
extends Reference
# One quadrant in a quadtree.

const MAX_DEPTH = 8


var _terrain: TerrainPatch   # Actual content of this quadtree node.
var _parent: QuadNode
var _top_left: QuadNode
var _top_right: QuadNode
var _bottom_left: QuadNode
var _bottom_right: QuadNode
var _depth: int


func _init(var _parent: QuadNode):
	if !_parent:
		_depth = 0
	else:
		self._parent = _parent
		_depth = _parent._depth + 1


func split():
	pass


func merge():
	pass
