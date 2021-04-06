class_name QuadCell
extends Reference

var terrainRef: TerrainFace

var parentCell: QuadCell
var cellTopLeft: QuadCell
var cellTopRight: QuadCell
var cellBottomLeft: QuadCell
var cellBottomRight: QuadCell
var depth: int

func _init(var _parentCell: QuadCell):
	self.parentCell = _parentCell
	if !parentCell:
		depth = 0
	else:
		depth = _parentCell.depth + 1
