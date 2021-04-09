tool
class_name TerrainPatch
extends MeshInstance
# Represents a patch of terrain tied to a quad tree node.

const Const = preload("../constants.gd")

var data: PatchData
#onready var _collider := $StaticBody/CollisionShape


func _process(_delta):
	data.quadnode.visit()


# Builds the mesh from generator data.
func build(var data: PatchData):
	set_visible(false)
	self.data = data
	# Start generating.
	var verts_per_edge = data.verts_per_edge
	var vertices := PoolVector3Array()
	vertices.resize(verts_per_edge * verts_per_edge)
	var triangles := PoolIntArray()
	# Number of triangles: (_verts_per_edge - 1)² * 3 vertices * 2 triangles
	triangles.resize((verts_per_edge - 1) * (verts_per_edge - 1) * 3 * 2)
	var uvs := PoolVector2Array()
	uvs.resize(verts_per_edge * verts_per_edge)
	# Some precalculations.
	var border_offset := 1.0 + Const.BORDER_SIZE * 2.0 / (data.settings.resolution - 1)
	var axis_a_scaled := data.axis_a * border_offset
	var axis_b_scaled := data.axis_b * border_offset
	var base_offset := data.axis_up + data.offset_a + data.offset_b
	# Build the mesh.
	var tri_idx: int = 0   # Mapping of vertex index to triangle
	for y in verts_per_edge:
		for x in verts_per_edge:
			# Calculate position of this vertex.
			var vertex_idx: int = y + x * verts_per_edge
			var percent: Vector2 = Vector2(x, y) / (verts_per_edge - 1)
			var point_on_unit_cube: Vector3 = base_offset \
										 + (percent.x - .5) * 2.0 * axis_a_scaled \
										 + (percent.y - .5) * 2.0 * axis_b_scaled
			var point_on_unit_sphere: Vector3 = point_on_unit_cube.normalized()
			var elevation: float = data.shape_gen.get_unscaled_elevation(point_on_unit_sphere)
			vertices[vertex_idx] = point_on_unit_sphere \
					* data.shape_gen.get_scaled_elevation(elevation)
			uvs[vertex_idx].x = elevation
			# Build two triangles that form one quad of this patch.
			if x != verts_per_edge - 1 && y != verts_per_edge - 1:
				triangles[tri_idx]     = vertex_idx
				triangles[tri_idx + 1] = vertex_idx + verts_per_edge + 1
				triangles[tri_idx + 2] = vertex_idx + verts_per_edge
				triangles[tri_idx + 3] = vertex_idx
				triangles[tri_idx + 4] = vertex_idx + 1
				triangles[tri_idx + 5] = vertex_idx + verts_per_edge + 1
				tri_idx += 6
	# Prepare mesh arrays.
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = calc_lowered_border(vertices)
	arrays[Mesh.ARRAY_NORMAL] = calc_normals(vertices, triangles)
	arrays[Mesh.ARRAY_TEX_UV] = calc_uvs(uvs)
	arrays[Mesh.ARRAY_INDEX]  = triangles
	# Create the mesh from data arrays and set the material.
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	if not Engine.editor_hint \
			and PGGlobals.colored_patches \
			and data.material is SpatialMaterial:
		data.material = data.material.duplicate()
		data.material.albedo_color = Color(randi())
	mesh.surface_set_material(0, data.material)
	# TODO: Initialize collision shape from terrain faces.
	#var collision_polygon = ConcavePolygonShape.new()
	#collision_polygon.set_faces(mesh.get_faces())
	#$StaticBody/CollisionShape.set_shape(collision_polygon)


# Prevents jagged LOD borders by lowering border vertices.
func calc_lowered_border(var vertices: PoolVector3Array) -> PoolVector3Array:
	var verts_per_edge = data.verts_per_edge
	# Top and bottom border.
	for i in range(0, verts_per_edge * verts_per_edge, verts_per_edge):
		var idx: = i
		vertices[idx] -= vertices[idx] * data.size * Const.BORDER_DIP
		idx = i + verts_per_edge - 1
		vertices[idx] -= vertices[idx] * data.size * Const.BORDER_DIP
	# Left and right border.
	for i in range(1, verts_per_edge - 1):
		var idx: = i
		vertices[idx] -= vertices[idx] * data.size * Const.BORDER_DIP
		idx = i + verts_per_edge*(verts_per_edge-1)
		vertices[idx] -= vertices[idx] * data.size * Const.BORDER_DIP
	return vertices


# Calculates smooth normals for all vertices by averaging (normalizing) patch normals.
func calc_normals(var vertices: PoolVector3Array,
			var triangles: PoolIntArray) -> PoolVector3Array:
	var normals: PoolVector3Array = PoolVector3Array()
	normals.resize(data.verts_per_edge * data.verts_per_edge)
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
	return normals


# Get UV coordinates into the appropriate range.
func calc_uvs(var uvs: PoolVector2Array) -> PoolVector2Array:
	var min_max: MinMax = data.shape_gen.terrain_min_max
	var min_value := min_max.get_min_value()
	var max_value := min_max.get_max_value()
	for i in uvs.size():
		uvs[i].x = range_lerp(uvs[i].x, min_value, max_value, 0, 1)
	return uvs
