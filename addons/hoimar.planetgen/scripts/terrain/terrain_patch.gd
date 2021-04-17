tool
class_name TerrainPatch
# Represents a patch of terrain tied to a quad tree node.
extends Spatial

const Const := preload("../constants.gd")

var data: PatchData
var quadnode: Reference
var vertices: PoolVector3Array
var triangles: PoolIntArray
var uvs: PoolVector2Array
var normals: PoolVector3Array

var _body_rid = RID()
var _mesh_rid = RID()
var _collider_rid = RID()

var initial_layer: int = 1
var initial_mask: int = 1

onready var _mesh := $Body/Mesh
#onready var _collider := $Body/Collider


func init():
	_mesh = get_node("Body/Mesh")
	
	_body_rid = PhysicsServer.body_create(PhysicsServer.BODY_MODE_STATIC)
	_collider_rid = PhysicsServer.shape_create(PhysicsServer.SHAPE_HEIGHTMAP)

	# Set initial collision layer and mask
	PhysicsServer.body_set_collision_layer(_body_rid, initial_layer)
	PhysicsServer.body_set_collision_mask(_body_rid, initial_mask)

	PhysicsServer.shape_set_data(_collider_rid, {
		"width": 2,
		"depth": 2,
		"heights": PoolRealArray([0, 0, 0, 0]),
		"min_height": -1,
		"max_height": 1
	})

	PhysicsServer.body_add_shape(_body_rid, _collider_rid)
	
	# This makes collision hits report the provided object as `collider`
	PhysicsServer.body_attach_object_instance_id(_body_rid, get_instance_id())
	
func _process(_delta):
	if quadnode:
		quadnode.visit()

# Builds the terrain mesh from generator data.
func build(var data: PatchData):
	self.data           = data
	self.quadnode       = data.quadnode
	var verts_per_edge  = data.verts_per_edge
	var resolution 		= verts_per_edge * verts_per_edge
	var border_offset  := 1.0 + Const.BORDER_SIZE * 2.0 / (data.settings.resolution - 1)
	var base_offset    := data.axis_up + data.offset_a + data.offset_b
	var axis_a_scaled  := data.axis_a * border_offset * 2.0
	var axis_b_scaled  := data.axis_b * border_offset * 2.0
	var tri_idx        := 0   # Mapping of vertex index to triangle
	var min_max        := MinMax.new()   # Store local min and max elevation.
	var shape_gen: ShapeGenerator = data.settings.shape_generator
	var elevations := PoolRealArray()
	
	self.init()
	
	# Number of triangles: (verts_per_edge - 1)² * 3 vertices * 2 triangles
	triangles.resize((verts_per_edge - 1) * (verts_per_edge - 1) * 3 * 2)
	vertices.resize(resolution)
	uvs.resize(resolution)
	normals.resize(resolution)
	elevations.resize(resolution)
	set_visible(false)
	
	# Build the mesh.
	for vertex_idx in verts_per_edge * verts_per_edge:
		var x: int = vertex_idx / verts_per_edge
		var y: int = vertex_idx % verts_per_edge
		# Calculate position of this vertex.
		var percent: Vector2 = Vector2(x, y) / (verts_per_edge - 1)
		var point_on_unit_cube := base_offset \
				 + (percent.x - 0.5) * axis_a_scaled \
				 + (percent.y - 0.5) * axis_b_scaled
		var point_on_unit_sphere: Vector3 = point_on_unit_cube.normalized()
		var elevation: float = shape_gen.get_unscaled_elevation(point_on_unit_sphere)
		elevations[vertex_idx] = elevation
		vertices[vertex_idx] = point_on_unit_sphere \
				* shape_gen.get_scaled_elevation(elevation)
		uvs[vertex_idx].x = elevation
		min_max.add_value(elevation)
		# Build two triangles that form one quad of this patch.
		if x < verts_per_edge - 1 and y < verts_per_edge - 1:
			triangles[tri_idx]     = vertex_idx
			triangles[tri_idx + 1] = vertex_idx + verts_per_edge + 1
			triangles[tri_idx + 2] = vertex_idx + verts_per_edge
			triangles[tri_idx + 3] = vertex_idx
			triangles[tri_idx + 4] = vertex_idx + 1
			triangles[tri_idx + 5] = vertex_idx + verts_per_edge + 1
			tri_idx += 6
	
	# Adjust global min_max.
	shape_gen.min_max_mutex.lock()
	shape_gen.min_max.add_value(min_max.min_value)
	shape_gen.min_max.add_value(min_max.max_value)
	shape_gen.min_max_mutex.unlock()
	# Additional calculations on mesh.
	calc_normals()
	calc_terrain_border()
	calc_uvs()
	
	# Prepare mesh arrays.
	var mesh_arrays := []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX]  = triangles
	_mesh.mesh = ArrayMesh.new()
	_mesh.mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# Special material needed?
	if not Engine.editor_hint \
			and PGGlobals.colored_patches \
			and data.material is SpatialMaterial:
		data.material = data.material.duplicate()
		data.material.albedo_color = Color(randi())
	
	# Create the mesh from data arrays and set the material.
	_mesh.mesh.surface_set_material(0, data.material)
	
	var shape_data = {
		"width": verts_per_edge,
		"depth": verts_per_edge,
		"heights": elevations,
		"min_height":  min_max.min_value,
		"max_height":  min_max.max_value
	}

	PhysicsServer.shape_set_data(_collider_rid, shape_data)


# Prevents jagged LOD borders by lowering border vertices.
func calc_terrain_border():
	var verts_per_edge = data.verts_per_edge
	var dip: float = pow(Const.BORDER_DIP, data.size)
	
	# Top and bottom border.
	for i in range(0, verts_per_edge * verts_per_edge, verts_per_edge):
		var idx: = i
		vertices[idx] *= dip
		idx = i + verts_per_edge - 1
		vertices[idx] *= dip
	
	# Left and right border.
	for i in range(1, verts_per_edge - 1):
		var idx: = i
		vertices[idx] *= dip
		idx = i + verts_per_edge * (verts_per_edge - 1)
		vertices[idx] *= dip


# Calculates smooth normals for all vertices by averaging (normalizing) patch normals.
func calc_normals():
	for i in range(0, triangles.size(), 3):
		var vi_a := triangles[i]
		var vi_b := triangles[i+1]
		var vi_c := triangles[i+2]
		var a := vertices[vi_a]
		var b := vertices[vi_b]
		var c := vertices[vi_c]
		var norm: Vector3 = -(b - a).cross(c - a)
		normals[vi_a] += norm
		normals[vi_b] += norm
		normals[vi_c] += norm
	for i in normals.size():
		normals[i] = normals[i].normalized()


# Get UV coordinates into the appropriate range.
func calc_uvs():
	var min_max: MinMax = data.settings.shape_generator.min_max
	var min_value := min_max.min_value
	var max_value := min_max.max_value
	for i in uvs.size():
		uvs[i].x = range_lerp(uvs[i].x, min_value, max_value, 0.0, 1.0)
