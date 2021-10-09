tool
class_name TerrainPatch
# Represents a patch of terrain tied to a quad tree node.
extends MeshInstance

const Const := preload("../constants.gd")

var data: PatchData
var quadnode: Reference
var vertices: PoolVector3Array
var triangles: PoolIntArray
var uvs: PoolVector2Array
var normals: PoolVector3Array
var faces: PoolVector3Array   # Vertices in a format that physics can use.

var _body_rid: RID    # Godot's internal resource ID for the physics body.
var _shape_rid: RID   # As above, but for the bodies' shape.


# Node enters scene tree. Finish configuring physics.
func _ready():
	if _body_rid:
		PhysicsServer.body_set_space(_body_rid, get_world().space)


func _process(_delta):
	if quadnode:
		quadnode.visit()


func _notification(what):
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		update_transform()   # Manually update physics shape position.


# Builds the terrain mesh from generator data.
func build(var data: PatchData):
	self.data           = data
	self.quadnode       = data.quadnode
	var verts_per_edge  = data.verts_per_edge
	var num_verts       = verts_per_edge * verts_per_edge
	var border_offset  := 1.0 + Const.BORDER_SIZE * 2.0 / (data.settings.resolution - 1)
	var base_offset    := data.axis_up + data.offset_a + data.offset_b
	var axis_a_scaled  := data.axis_a * border_offset * 2.0
	var axis_b_scaled  := data.axis_b * border_offset * 2.0
	var tri_idx        := 0   # Mapping of vertex index to triangle
	var min_max        := MinMax.new()   # Store local min and max elevation.
	var shape_gen: ShapeGenerator = data.settings.shape_generator
	# Number of triangles: (verts_per_edge - 1)² * 3 vertices * 2 triangles
	triangles.resize((verts_per_edge - 1) * (verts_per_edge - 1) * 3 * 2)
	vertices.resize(num_verts)
	uvs.resize(num_verts)
	normals.resize(num_verts)
	
	# Build the mesh.
	for vertex_idx in num_verts:
		var x: int = vertex_idx / verts_per_edge
		var y: int = vertex_idx % verts_per_edge
		# Calculate position of this vertex.
		var percent: Vector2 = Vector2(x, y) / (verts_per_edge - 1)
		var point_on_unit_cube := base_offset \
				 + (percent.x - 0.5) * axis_a_scaled \
				 + (percent.y - 0.5) * axis_b_scaled
		var point_on_unit_sphere: Vector3 = point_on_unit_cube.normalized()
		var elevation: float = shape_gen.get_unscaled_elevation(point_on_unit_sphere)
		vertices[vertex_idx] = point_on_unit_sphere \
				* shape_gen.get_scaled_elevation(elevation)
		uvs[vertex_idx].x = elevation
		min_max.add_value(elevation)
		# Build two triangles that form one quad like so:
		# 0--2   0  2
		#  \ |   | \
		# 1  3   1--3
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
	# Manipulate vertices.
	calc_normals()          # Calculate normals before dipping border vertices,
	calc_terrain_border()   # resulting in smoother terrain patch edges.
	calc_uvs()
	
	if Const.COLLISIONS_ENABLED and data.settings.has_collisions:
		init_physics()
	
	# Prepare mesh arrays and create mesh.
	var mesh_arrays := []
	mesh_arrays.resize(Mesh.ARRAY_MAX)
	mesh_arrays[Mesh.ARRAY_VERTEX] = vertices
	mesh_arrays[Mesh.ARRAY_NORMAL] = normals
	mesh_arrays[Mesh.ARRAY_TEX_UV] = uvs
	mesh_arrays[Mesh.ARRAY_INDEX]  = triangles
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, mesh_arrays)
	
	# Special material needed?
	if not Engine.editor_hint \
			and PGGlobals.colored_patches \
			and data.material is SpatialMaterial:
		data.material = data.material.duplicate()
		data.material.albedo_color = Color(randi())
	mesh.surface_set_material(0, data.material)
	set_visible(false)


# Create physics body & shape.
# TODO: PhysicsServer is not multi-threading safe here, should be fixed in 4.0.
func init_physics():
	data.settings.shared_mutex.lock()
	_shape_rid = PhysicsServer.shape_create(PhysicsServer.SHAPE_CONCAVE_POLYGON)
	_body_rid  = PhysicsServer.body_create(PhysicsServer.BODY_MODE_STATIC)
	data.settings.shared_mutex.unlock()
	calc_face_vertices()   # Prepare array with ordered face vertices.
	update_transform()
	PhysicsServer.shape_set_data(_shape_rid, faces)
	PhysicsServer.body_add_shape(_body_rid, _shape_rid)
	PhysicsServer.body_set_shape_disabled(_body_rid, 0, true)
	PhysicsServer.body_set_collision_layer(_body_rid, 1)
	PhysicsServer.body_set_collision_mask(_body_rid, 1)


func update_transform():
	var transform: Transform = data.settings._planet.global_transform
	PhysicsServer.body_set_state(_body_rid, PhysicsServer.BODY_STATE_TRANSFORM,
			transform)


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


# Calculates smooth normals for all vertices by averaging (normalizing) mesh
# normals. This is done by accumulating the normals calculated from triangles
# and normalizing the resulting vector, thus building an average.
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


# Returns the meshes vertices, ordered as triangle points (a, b, c, a, b, c, …).
func calc_face_vertices():
	faces.resize(triangles.size())
	for i in triangles.size():
		# face vertex = vertices at index of current triangle point.
		faces[i] = vertices[triangles[i]]
	return faces


func set_visible(visible: bool):
	# Enable/disable shape when visibility of this patch changes.
	if _body_rid:
		PhysicsServer.body_set_shape_disabled(_body_rid, 0, !visible)
	.set_visible(visible)


func _exit_tree():
	if _body_rid:
		PhysicsServer.free_rid(_body_rid)
	if _shape_rid:
		PhysicsServer.free_rid(_shape_rid)
