class_name PatchData
extends Reference

const Const = preload("../constants.gd")

var parent_patch: MeshInstance   # Parent patch in the quad tree.
var quadnode: Reference
var manager: Spatial    # Top level TerrainManager node to contain all patches.
var settings: PlanetSettings
var shape_gen: ShapeGenerator
var axis_up: Vector3      # Normal of flat cube patch.
var axis_a: Vector3       # Axis perpendicular to the normal.
var axis_b: Vector3       # Axis perpendicular to both above.
var verts_per_edge: int   # Amount of vertices with border (so resolution + BORDER_SIZE * 2).
var offset_a: Vector3     # Offsets this patch to it's quadtree cell along axis a.
var offset_b: Vector3     # Offsets this patch to it's quadtree cell along axis b.
var size: float           # Size of this quad. 1 is a full cube patch, 0.5 a quarter etc.
var center: Vector3
var material: Material


func _init(
			manager: Spatial, \
			quadnode: Reference, \
			axis_up: Vector3, \
			offset: Vector2):
	self.quadnode       = quadnode
	if quadnode.parent:
		self.parent_patch   = quadnode.parent.terrain
	self.manager        = manager
	self.settings       = manager.planet_settings
	self.shape_gen      = settings.shape_generator
	self.size           = quadnode._size
	self.axis_up        = axis_up.normalized()
	self.axis_a         = Vector3(self.axis_up.y, self.axis_up.z, self.axis_up.x) * size
	self.axis_b         = self.axis_up.cross(axis_a).normalized() * size
	self.offset_a       = Vector3(self.axis_a * offset.x)
	self.offset_b       = Vector3(self.axis_b * offset.y)
	if self.parent_patch:
		self.offset_a += parent_patch.data.offset_a
		self.offset_b += parent_patch.data.offset_b
	self.verts_per_edge = settings.resolution + Const.BORDER_SIZE * 2
	self.center         = settings.radius * (self.axis_up + offset_a + offset_b).normalized()
	self.material       = manager.planet_material
