tool
class_name TerrainPatch
extends MeshInstance
# Represents one patch of terrain in the quad tree that's projected onto a sphere.

const USE_THREADS := true   # For single-threaded debugging.
const BORDER_SIZE := 1    # Don't change the vertex border, it will not be respected.
const BORDER_DIP := 0.2   # How much border vertices will be dipped in relation to patch _size.
const LOD_LEVELS := 7
const OFFSETS: Array = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]   # The four corners of a quad.
const MIN_DISTANCE: float = 4.75         # Define when LODs will be switched: min_distance * _size * radius
const MIN_SIZE: float = 1.0/pow(2, LOD_LEVELS)   # How many subdivisions are possible.
enum STATE {GENERATING, ACTIVE, SUBDIVIDING, SUBDIVIDED, OBSOLETE}

var _container: Spatial    # Top level TerrainContainer node to contain all patches.
var _settings: PlanetSettings
var _shape_gen: ShapeGenerator
var _axis_up: Vector3      # Normal of flat cube patch.
var _axis_a: Vector3       # Axis perpendicular to the normal.
var _axis_b: Vector3       # Axis perpendicular to both above.
var _resolution: int       # Amount of vertices per edge without border.
var _verts_per_edge: int   # Amount of vertices with border (so resolution + BORDER_SIZE * 2).
var _offset_a: Vector3     # Offsets this patch to it's quadtree cell along axis a.
var _offset_b: Vector3     # Offsets this patch to it's quadtree cell along axis b.
var _center: Position3D    # Center point of this patch.
var _size: float           # Size of this quad. 1 is a full cube patch, 0.5 a quarter etc.
var _material: Material

var parent_patch: TerrainPatch   # Parent patch in the quad tree.
var _child_patches: Array = []    # The child patches in the quad tree.

var _state: int
var thread: = Thread.new()


# Calculates if this patch needs to subdivide or merge.
func update(_delta, var view_pos: Vector3):
	var distance: float = view_pos.distance_to(_center.global_transform.origin)
	var needs_subdivision: bool = distance < MIN_DISTANCE * _size * _settings.radius
	match _state:
		STATE.ACTIVE:
			if needs_subdivision:
				make_subdivision()
			else:
				mark_obsolete()
		STATE.SUBDIVIDING:
			var finished: bool = true
			for child in _child_patches:
				if child.thread.is_active():
					finished = false
			if finished:
				finish_subdivision()
		STATE.OBSOLETE:
			if needs_subdivision:
				make_subdivision()
		STATE.SUBDIVIDED:
			if !needs_subdivision:
				var all_children_obsolete: bool = true
				for child in _child_patches:
					if child._state != STATE.OBSOLETE:
						all_children_obsolete = false
				if all_children_obsolete:
					# We don't need subdivision and all children are obsolete.
					merge()


# Initializes the patch and starts a thread to generate it.
func init(
			_container: Spatial, \
			_settings: PlanetSettings, \
			_axis_up: Vector3, \
			_material: Material = null, \
			_parent_patch: TerrainPatch = null, \
			_offset: Vector2 = Vector2(0, 0), \
			_size: float = 1.0):
	self._state = STATE.GENERATING
	self._container = _container
	self._settings = _settings
	self._size = _size
	self._axis_up = _axis_up.normalized()
	self._axis_a = Vector3(_axis_up.y, _axis_up.z, _axis_up.x) * _size
	self._axis_b = _axis_up.cross(_axis_a).normalized() * _size
	self._resolution = _settings.resolution
	self._verts_per_edge = _resolution + BORDER_SIZE * 2
	self._offset_a = Vector3(_axis_a * _offset.x)
	self._offset_b = Vector3(_axis_b * _offset.y)
	# Do we have a parent patch or are we the top level patch?
	if _parent_patch:
		self.parent_patch = _parent_patch
		self._offset_a += _parent_patch._offset_a
		self._offset_b += _parent_patch._offset_b
	set_visible(false)
	self._material = _material
	self._center = Position3D.new()   # Add _center point of this patch as child.
	self._center.translate((_axis_up + _offset_a + _offset_b).normalized() * _settings.radius)
	self._shape_gen = _settings.shape_generator
	add_child(self._center)
	# Start generating.
	_container.register_terrain_patch(self)
	if USE_THREADS:
		var _unused = thread.start(self, "generate_patch")
	else:
		generate_patch()


# Builds this terrain patch.
func generate_patch(_args = null):
	var vertices := PoolVector3Array()
	vertices.resize(_verts_per_edge*_verts_per_edge)
	var triangles := PoolIntArray()
	# Number of triangles: (_verts_per_edge - 1)² * 3 vertices * 2 triangles
	triangles.resize((_verts_per_edge - 1) * (_verts_per_edge - 1) * 3 * 2)
	var uvs := PoolVector2Array()
	uvs.resize(_verts_per_edge*_verts_per_edge)
	# Some precalculations.
	var border_offset: float = 1.0 + BORDER_SIZE*2.0 / (_resolution-1)
	var axis_a_scaled := _axis_a * border_offset
	var axis_b_scaled := _axis_b * border_offset
	var base_offset := _axis_up + _offset_a + _offset_b
	# Build the mesh.
	var tri_idx: int = 0   # Mapping of vertex index to triangle
	for y in _verts_per_edge:
		for x in _verts_per_edge:
			# Calculate position of this vertex.
			var vertex_idx: int = y + x * _verts_per_edge;
			var percent: Vector2 = Vector2(x, y) / (_verts_per_edge - 1);
			var point_on_unit_cube: Vector3 = base_offset \
										 + (percent.x - .5) * 2.0 * axis_a_scaled \
										 + (percent.y - .5) * 2.0 * axis_b_scaled
			var point_on_unit_sphere: Vector3 = point_on_unit_cube.normalized()
			var elevation: float = _shape_gen.get_unscaled_elevation(point_on_unit_sphere)
			vertices[vertex_idx] = point_on_unit_sphere * _shape_gen.get_scaled_elevation(elevation)
			uvs[vertex_idx].x = elevation
			# Build two triangles that form one quad of this patch.
			if x != _verts_per_edge - 1 && y != _verts_per_edge - 1:
				triangles[tri_idx]     = vertex_idx
				triangles[tri_idx + 1] = vertex_idx + _verts_per_edge + 1
				triangles[tri_idx + 2] = vertex_idx + _verts_per_edge
				triangles[tri_idx + 3] = vertex_idx
				triangles[tri_idx + 4] = vertex_idx + 1
				triangles[tri_idx + 5] = vertex_idx + _verts_per_edge + 1
				tri_idx += 6
	# Prepare mesh arrays.
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = calc_lowered_border(vertices)
	arrays[Mesh.ARRAY_INDEX]  = triangles
	arrays[Mesh.ARRAY_NORMAL] = calc_normals(vertices, triangles)
	arrays[Mesh.ARRAY_TEX_UV] = calc_uvs(uvs)
	apply_mesh(arrays)
	_state = STATE.ACTIVE
	_container.call_deferred("finish_terrain_patch", self)


# Prevents jagged LOD borders by lowering border vertices.
func calc_lowered_border(var vertices: PoolVector3Array) -> PoolVector3Array:
	# Top and bottom border.
	for i in range(0, _verts_per_edge * _verts_per_edge, _verts_per_edge):
		var idx: = i
		vertices[idx] -= vertices[idx] * _size * BORDER_DIP
		idx = i + _verts_per_edge - 1
		vertices[idx] -= vertices[idx] * _size * BORDER_DIP
	# Left and right border.
	for i in range(1, _verts_per_edge - 1):
		var idx: = i
		vertices[idx] -= vertices[idx] * _size * BORDER_DIP
		idx = i + _verts_per_edge*(_verts_per_edge-1)
		vertices[idx] -= vertices[idx] * _size * BORDER_DIP
	return vertices


# Calculates smooth normals for all vertices by averaging (normalizing) patch normals.
func calc_normals(var vertices: PoolVector3Array,
			var triangles: PoolIntArray) -> PoolVector3Array:
	var normals: PoolVector3Array = PoolVector3Array()
	normals.resize(_verts_per_edge*_verts_per_edge)
	for i in range(0, triangles.size(), 3):
		var vi_a := triangles[i]
		var vi_b := triangles[i+1]
		var vi_c := triangles[i+2]
		var a := vertices[vi_a]
		var b := vertices[vi_b]
		var c := vertices[vi_c]
		var norm: Vector3 = -(b-a).cross(c-a)
		normals[vi_a] += norm
		normals[vi_b] += norm
		normals[vi_c] += norm
	for i in normals.size():
		normals[i] = normals[i].normalized()
	return normals


# Get UV coordinates into the appropriate range.
func calc_uvs(var uvs: PoolVector2Array) -> PoolVector2Array:
	var min_max: MinMax = _shape_gen.terrain_min_max
	var min_value := min_max.get_min_value()
	var max_value := min_max.get_max_value()
	for i in uvs.size():
		uvs[i].x = range_lerp(uvs[i].x, min_value, max_value, 0, 1)
	return uvs


func apply_mesh(var meshArrays: Array):
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshArrays)
	if !Engine.editor_hint and PGGlobals.colored_patches and _material is SpatialMaterial:
		_material = _material.duplicate()
		_material.albedo_color = Color(randi())
	mesh.surface_set_material(0, _material)


# Subdivide this patch into four smaller ones.
func make_subdivision():
	if _size <= MIN_SIZE:
		return
	for offset in OFFSETS:
		var child_patch: TerrainPatch = get_script().new()   # Workaround because of cyclic reference limitations.
		child_patch.init(_container, _settings, _axis_up, _material, self, offset, _size/2.0)
		_child_patches.append(child_patch)
	_state = STATE.SUBDIVIDING


# Patches finished generating, so add them and hide ourselves.
func finish_subdivision():
	for patch in _child_patches:
		_container.add_child(patch)
		patch.set_visible(true)
	set_visible(false)
	_state = STATE.SUBDIVIDED


# Mark this patch obsolete.
func mark_obsolete():
	for patch in _child_patches:
		patch.queue_free()
	_child_patches.clear()
	_state = STATE.OBSOLETE


# Merge child patches and reactivate this patch.
func merge():
	for patch in _child_patches:
		patch.queue_free()
	_child_patches.clear()
	set_visible(true)
	_state = STATE.ACTIVE
