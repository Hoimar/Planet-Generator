# Represents one patch of terrain in the quad tree that's projected onto a sphere.
tool
class_name TerrainFace
extends MeshInstance

const USE_THREADS := true   # For single-threaded debugging.

const BORDER_SIZE: = 1    # Don't change the vertex border, it will not be respected.
const BORDER_DIP: = 0.2   # How much border vertices will be dipped in relation to face size.
const LOD_LEVELS := 8
const OFFSETS: Array = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]   # The four corners of a quad.
const MIN_DISTANCE: float = 4.5         # Define when LODs will be switched: min_distance * size * radius
const MIN_SIZE: float = 1.0/pow(2, LOD_LEVELS)   # How many subdivisions are possible.
enum STATE {GENERATING, ACTIVE, SUBDIVIDING, SUBDIVIDED, OBSOLETE}

var container: Spatial      # Top level TerrainContainer node to contain all faces.
var settings: PlanetSettings
var shapeGen: ShapeGenerator
var axisUp: Vector3         # Normal of flat cube face.
var axisA: Vector3          # Axis perpendicular to the normal.
var axisB: Vector3          # Axis perpendicular to both above.
var resolution: int         # Amount of vertices per edge without border.
var vertsPerEdge: int       # Amount of vertices with border (so resolution + BORDER_SIZE * 2).
var offsetA: Vector3        # Offsets this face to it's quadtree cell along axisA.
var offsetB: Vector3        # Offsets this face to it's quadtree cell along axisA.
var center: Position3D      # Center point of this face.
var size: float             # Size of this quad. 1 is a full cube face, 0.5 a quarter etc.
var material: Material

var parentFace: TerrainFace   # Parent face in the quad tree.
var childFaces: Array = []    # The child faces in the quad tree.

var state: int
var thread: = Thread.new()


# Calculates if this face needs to subdivide or merge.
func update(_delta, var viewPos: Vector3):
	var distance: float = viewPos.distance_to(center.global_transform.origin)
	var needsSubdivision: bool = distance < MIN_DISTANCE * size * settings.radius
	if state == STATE.ACTIVE:
		if needsSubdivision:
			makeSubdivision()
		else:
			markObsolete()
	elif state == STATE.SUBDIVIDING:
		var finished: bool = true
		for child in childFaces:
			if child.thread.is_active():
				finished = false
		if finished:
			finishSubdivision()
	elif state == STATE.OBSOLETE:
		if needsSubdivision:
			makeSubdivision()
	elif state == STATE.SUBDIVIDED:
		if !needsSubdivision:
			var allChildrenObsolete: bool = true
			for child in childFaces:
				if child.state != STATE.OBSOLETE:
					allChildrenObsolete = false
			if allChildrenObsolete:
				# We don't need subdivision and all children are obsolete.
				merge()


# Initializes the face and starts a thread to generate it.
func init(  _container: Spatial, \
			_settings: PlanetSettings, \
			_axisUp: Vector3, \
			_material: Material = null, \
			_parentFace: TerrainFace = null, \
			_offset: Vector2 = Vector2(0, 0), \
			_size: float = 1.0):
	self.state = STATE.GENERATING
	self.container = _container
	self.settings = _settings
	self.size = _size
	self.axisUp = _axisUp.normalized()
	self.axisA = Vector3(axisUp.y, axisUp.z, axisUp.x) * size
	self.axisB = axisUp.cross(axisA).normalized() * size
	self.resolution = _settings.resolution
	self.vertsPerEdge = resolution + BORDER_SIZE * 2
	self.offsetA = Vector3(axisA * _offset.x)
	self.offsetB = Vector3(axisB * _offset.y)
	# Do we have a parent face or are we the top level face?
	if _parentFace:
		self.parentFace = _parentFace
		self.offsetA += _parentFace.offsetA
		self.offsetB += _parentFace.offsetB
	set_visible(false)
	self.material = _material
	self.center = Position3D.new()   # Add center point of this face as child.
	self.center.translate((axisUp + offsetA + offsetB).normalized() * settings.radius)
	self.shapeGen = settings.shapeGenerator
	add_child(self.center)
	# Start generating.
	container.registerTerrainFace(self)
	if USE_THREADS:
		var _unused = thread.start(self, "generateFace")
	else:
		generateFace()


# Builds this terrain face.
func generateFace(_args = null):
	var time_start = OS.get_ticks_msec()

	var vertices := PoolVector3Array()
	vertices.resize(vertsPerEdge*vertsPerEdge)
	var triangles := PoolIntArray()
	# Number of triangles: (vertsPerEdge - 1)² * 3 vertices * 2 triangles
	triangles.resize((vertsPerEdge - 1) * (vertsPerEdge - 1) * 3 * 2)
	var uvs := PoolVector2Array()
	uvs.resize(vertsPerEdge*vertsPerEdge)
	
	# Some precalculations.
	var borderOffset: float = 1.0 + BORDER_SIZE*2.0 / (resolution-1)
	var axisAScaled := axisA * borderOffset
	var axisBScaled := axisB * borderOffset
	var baseOffset := axisUp + offsetA + offsetB
	# Build the mesh.
	var triIndex: int = 0   # Mapping of vertex index to triangle
	for y in vertsPerEdge:
		for x in vertsPerEdge:
			# Calculate position of this vertex.
			var vertexIdx: int = y + x * vertsPerEdge;
			var percent: Vector2 = Vector2(x, y) / (vertsPerEdge - 1);
			var pointOnUnitCube: Vector3 = baseOffset \
										 + (percent.x - .5) * 2.0 * axisAScaled \
										 + (percent.y - .5) * 2.0 * axisBScaled
			var pointOnUnitSphere: Vector3 = pointOnUnitCube.normalized()
			var elevation: float = shapeGen.getUnscaledElevation(pointOnUnitSphere)
			vertices[vertexIdx] = pointOnUnitSphere * shapeGen.getScaledElevation(elevation)
			uvs[vertexIdx].x = elevation
			# Build two triangles that form one quad of this face.
			if x != vertsPerEdge - 1 && y != vertsPerEdge - 1:
				triangles[triIndex]     = vertexIdx
				triangles[triIndex + 1] = vertexIdx + vertsPerEdge + 1
				triangles[triIndex + 2] = vertexIdx + vertsPerEdge
				triangles[triIndex + 3] = vertexIdx
				triangles[triIndex + 4] = vertexIdx + 1
				triangles[triIndex + 5] = vertexIdx + vertsPerEdge + 1
				triIndex += 6
	# Prepare mesh arrays.
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = calcLoweredBorder(vertices)
	arrays[Mesh.ARRAY_INDEX]  = triangles
	arrays[Mesh.ARRAY_NORMAL] = calcNormals(vertices, triangles)
	arrays[Mesh.ARRAY_TEX_UV] = calcUVs(uvs)
	setMesh(arrays)
	state = STATE.ACTIVE
	container.call_deferred("finishTerrainFace", self)


# Prevents jagged LOD borders by lowering border vertices.
func calcLoweredBorder(var vertices: PoolVector3Array) -> PoolVector3Array:
	# Top and bottom border.
	for i in range(0, vertsPerEdge*vertsPerEdge, vertsPerEdge):
		var idx: = i
		vertices[idx] -= vertices[idx] * size * BORDER_DIP
		#print("top ", idx)
		idx = i + vertsPerEdge - 1
		vertices[idx] -= vertices[idx] * size * BORDER_DIP
		#print("bottom ", idx)
	# Left and right border.
	for i in range(1, vertsPerEdge-1):
		var idx: = i
		vertices[idx] -= vertices[idx] * size * BORDER_DIP
		#print("left ", idx)
		idx = i + vertsPerEdge*(vertsPerEdge-1)
		vertices[idx] -= vertices[idx] * size * BORDER_DIP
		#print("right ", idx)
	return vertices


# Calculates smooth normals for all vertices by averaging (normalizing) face normals.
func calcNormals(	var vertices: PoolVector3Array,
						var triangles: PoolIntArray) -> PoolVector3Array:
	var normals: PoolVector3Array = PoolVector3Array()
	normals.resize(vertsPerEdge*vertsPerEdge)
	for i in range(0, triangles.size(), 3):
		var vertexIdx1 = triangles[i]
		var vertexIdx2 = triangles[i+1]
		var vertexIdx3 = triangles[i+2]
		var a := vertices[vertexIdx1]
		var b := vertices[vertexIdx2]
		var c := vertices[vertexIdx3]
		var norm: Vector3 = -(b-a).cross(c-a)
		normals[vertexIdx1] += norm
		normals[vertexIdx2] += norm
		normals[vertexIdx3] += norm
	for i in normals.size():
		normals[i] = normals[i].normalized()
	return normals


# Get UV coordinates into the appropriate range.
func calcUVs(var uvs: PoolVector2Array) -> PoolVector2Array:
	var minMax: MinMax = shapeGen.terrainMinMax
	for i in uvs.size():
		uvs[i].x = range_lerp(uvs[i].x, minMax.minValue, minMax.maxValue, 0, 1)
	return uvs


func setMesh(var meshArrays: Array):
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshArrays)
	if !Engine.editor_hint and PGGlobals.coloredFaces and material is SpatialMaterial:
		material = material.duplicate()
		material.albedo_color = Color(randi())
	mesh.surface_set_material(0, material)


# Subdivide this face into four smaller ones.
func makeSubdivision():
	if size <= MIN_SIZE:
		return
	for offset in OFFSETS:
		var childFace: TerrainFace = get_script().new()   # Workaround because of cyclic reference limitations.
		childFace.init(container, settings, axisUp, material, self, offset, size/2.0)
		childFaces.append(childFace)
	state = STATE.SUBDIVIDING


# Faces finished generating, so add them and hide ourselves.
func finishSubdivision():
	for terrainFace in childFaces:
		container.add_child(terrainFace)
		terrainFace.set_visible(true)
	set_visible(false)
	state = STATE.SUBDIVIDED


# Mark this face obsolete.
func markObsolete():
	for face in childFaces:
		face.queue_free()
	childFaces.clear()
	state = STATE.OBSOLETE


# Merge child faces and reactivate this face.
func merge():
	for face in childFaces:
		face.queue_free()
	childFaces.clear()
	set_visible(true)
	state = STATE.ACTIVE
