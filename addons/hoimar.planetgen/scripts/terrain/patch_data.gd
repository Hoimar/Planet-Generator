class_name PatchData

# Data class which holds information for one patch of terrain.

const Const := preload("../constants.gd")

var parent_patch: Spatial   # Parent patch in the quad tree.
var quadnode: Reference
var settings: PlanetSettings
var axis_up: Vector3      # Normal of flat cube patch.
var axis_a: Vector3       # Axis perpendicular to the normal.
var axis_b: Vector3       # Axis perpendicular to both above.
var verts_per_edge: int   # Amount of vertices with border (so resolution + BORDER_SIZE * 2).
var offset_a: Vector3     # Offsets this patch to it's quadtree cell along axis a.
var offset_b: Vector3     # Offsets this patch to it's quadtree cell along axis b.
var size: float           # Size of this quad. 1 is a full cube patch, 0.5 a quarter etc.
var center: Vector3
var material: Material


func _init(manager: Spatial, quadnode: Reference,
		axis_up: Vector3, offset: Vector2):
	self.quadnode  = quadnode
	settings       = manager.planet_settings
	material       = manager.planet_material
	size           = quadnode._size
	axis_up        = axis_up.normalized()
	self.axis_up   = axis_up
	axis_a         = Vector3(axis_up.y, axis_up.z, axis_up.x) * size
	axis_b         = axis_up.cross(axis_a).normalized() * size
	offset_a       = Vector3(axis_a * offset.x)
	offset_b       = Vector3(axis_b * offset.y)
	
	if quadnode.parent:
		parent_patch = quadnode.parent.terrain
	if parent_patch:
		offset_a += parent_patch.data.offset_a
		offset_b += parent_patch.data.offset_b
	verts_per_edge = settings.resolution + Const.BORDER_SIZE * 2
	center         = settings.radius * (axis_up + offset_a + offset_b).normalized()
