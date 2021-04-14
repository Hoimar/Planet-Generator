tool
class_name TerrainManager
extends Spatial

const Const := preload("../constants.gd")

var _cube_quadtree: CubeQuadTree
var planet_settings: PlanetSettings
var planet_material: Material
var _logger := Logger.get_for(self)


# Remove old patches, initialize quadtrees to build terrain patches.
func generate(var settings: PlanetSettings, var material: Material):
	planet_settings = settings
	planet_material = material
	# Free all existing terrain patches.
	for child in get_children():
		child.queue_free()
	# Create the quadtree with new terrain patches.
	_cube_quadtree = CubeQuadTree.new(self)


func set_viewer(var viewer: Spatial):
	if _cube_quadtree:
		_cube_quadtree.set_viewer(viewer)
