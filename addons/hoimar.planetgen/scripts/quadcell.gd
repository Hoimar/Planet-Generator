class_name QuadCell
extends Reference
# One cell in a quadtree.

var terrain_ref: TerrainFace
var parent_cell: QuadCell
var cell_top_left: QuadCell
var cell_top_right: QuadCell
var cell_bottom_feft: QuadCell
var cell_bottom_right: QuadCell
var depth: int


func _init(var _parent_cell: QuadCell):
	if !parent_cell:
		depth = 0
	else:
		self.parent_cell = _parent_cell
		depth = _parent_cell.depth + 1
