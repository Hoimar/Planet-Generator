# Represents one patch of terrain in the quad tree that's projected onto a sphere.
tool
extends MeshInstance

class_name TerrainFace

# The four corners of a quad.
const OFFSETS: Array = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]
const MIN_DISTANCE: float = 4.5         # Distance in relation to current face size and radius of the planet.
const MIN_SIZE: float = 1.0/pow(2, 8)   # How many subdivisions are possible.
enum STATE {GENERATING, ACTIVE, SUBDIVIDING, SUBDIVIDED, OBSOLETE}

var planet: Spatial      # Node in the scene hierarchy to contain the faces.
var shapeGen: ShapeGenerator
var axisUp: Vector3      # Normal of flat cube face.
var axisA: Vector3       # Axis perpendicular to the normal.
var axisB: Vector3       # Axis perpendicular to both above.
var resolution: int      # Subdivision level of this mesh.
var offsetA: Vector3     # Offset for every vertex to the correct "corner" on axisA.
var offsetB: Vector3     # Offset for every vertex to the correct "corner" on axisB.
var center: Position3D   # Center point of this face.
var size: float          # Size of this quad. 1 is a full cube face, 0.5 a quarter etc.
var material: Material

var parentFace: TerrainFace   # Parent face in the quad tree.
var childFaces: Array = []    # The child faces in the quad tree.

var state: int
var thread = Thread.new()
var mutex: Mutex


# Calculates if this face needs to subdivide or merge.
func update(delta, var viewPos: Vector3):
	var distance: float = viewPos.distance_to(center.global_transform.origin)
	var needsSubdivision: bool = distance < MIN_DISTANCE * size * planet.settings.radius
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
func init(  _planet: Spatial, \
			_axisUp: Vector3, \
			_resolution: int, \
			_material: Material = null, \
			_parentFace: TerrainFace = null, \
			_offset: Vector2 = Vector2(0, 0), \
			_size: float = 1):
	self.state = STATE.GENERATING
	self.planet = _planet
	self.axisUp = _axisUp.normalized()
	self.size = _size
	self.axisA = Vector3(axisUp.y, axisUp.z, axisUp.x) * size
	self.axisB = axisUp.cross(axisA).normalized() * size
	self.resolution = _resolution
	self.offsetA = Vector3(axisA * _offset.x)
	self.offsetB = Vector3(axisB * _offset.y)
	if _parentFace:
		self.parentFace = _parentFace
		self.offsetA += _parentFace.offsetA
		self.offsetB += _parentFace.offsetB
	self.material = _material
	# Add center point of this face as child.
	self.center = Position3D.new()
	self.center.translate((axisUp + offsetA + offsetB).normalized() * planet.settings.radius)
	self.add_child(self.center)
	self.shapeGen = planet.settings.shapeGenerator
	# Start generation.
	mutex = Mutex.new()
	#if Engine.editor_hint:
	#	generateFace()
	#else:
	thread.start(self, "generateFace")

# Builds this terrain face.
func generateFace(args = null):
	var vertices = PoolVector3Array()
	vertices.resize(resolution*resolution)
	var triangles = PoolIntArray()
	# resolution - 1 (squares) squared times 2 triangles times 3 vertices
	triangles.resize((resolution - 1) * (resolution - 1) * 2 * 3)
	var uvs = PoolVector2Array()
	uvs.resize(resolution*resolution)
	
	# Build the mesh.
	var triIndex: int = 0   # Mapping of vertex index to triangle
	for y in range(0, resolution):
		for x in range(0, resolution):
			# Calculate position of this vertex.
			var vertexIdx: int = y + x * resolution;
			var percent: Vector2 = Vector2(x, y) / (resolution - 1);
			var pointOnUnitCube: Vector3 = axisUp \
										+ (percent.x - .5) * 2.0 * axisA \
										+ (percent.y - .5) * 2.0 * axisB \
										+ offsetA \
										+ offsetB
			var pointOnUnitSphere: Vector3 = pointOnUnitCube.normalized()
			var elevation = shapeGen.getUnscaledElevation(pointOnUnitSphere)
			vertices[vertexIdx] = pointOnUnitSphere * shapeGen.getScaledElevation(elevation)
			uvs[vertexIdx].x = elevation
			# Build two triangles that form one quad of this face.
			if x != resolution - 1 && y != resolution - 1:
				triangles[triIndex] = vertexIdx
				triangles[triIndex + 1] = vertexIdx + resolution + 1
				triangles[triIndex + 2] = vertexIdx + resolution
				
				triangles[triIndex + 3] = vertexIdx
				triangles[triIndex + 4] = vertexIdx + 1
				triangles[triIndex + 5] = vertexIdx + resolution + 1
				triIndex += 6
	
	# Calculate normals.
	var normals: PoolVector3Array = PoolVector3Array()
	normals.resize(resolution*resolution)
	for i in range(0, triangles.size(), 3):
		var vertexIdx1 = triangles[i]
		var vertexIdx2 = triangles[i+1]
		var vertexIdx3 = triangles[i+2]

		var v1 = vertices[vertexIdx1]
		var v2 = vertices[vertexIdx2]
		var v3 = vertices[vertexIdx3]
		
		# calculate normal for this face
		var norm: Vector3 = -(v2 - v1).normalized().cross((v3 - v1).normalized()).normalized()
		normals[vertexIdx1] = norm
		normals[vertexIdx2] = norm
		normals[vertexIdx3] = norm
	
	uvs = generateUVs(uvs)
	# Prepare mesh arrays.
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_TEX_UV] = uvs
	arrays[Mesh.ARRAY_INDEX] = triangles
	call_deferred("setMesh", arrays)
	state = STATE.ACTIVE
	thread.wait_to_finish()

# Get UV coordinates into the appropriate range.
func generateUVs(var uvs):
	var minMax: MinMax = shapeGen.terrainMinMax
	for i in range(0, uvs.size()):
		uvs[i].x = range_lerp(uvs[i].x, minMax.minValue, minMax.maxValue, 0, 1)
	return uvs

func setMesh(var meshArrays: Array):
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, meshArrays)
	if !Engine.editor_hint and Global.coloredFaces and material is SpatialMaterial:
		material = material.duplicate()
		material.albedo_color = Color(randi())
	mesh.surface_set_material(0, material)

# Subdivide this face into four smaller ones.
func makeSubdivision():
	if size <= MIN_SIZE:
		return
	for offset in OFFSETS:
		var childFace: TerrainFace = get_script().new()   # Workaround because of cyclic reference limitations.
		childFace.init(planet, axisUp, resolution, material, self, offset, size/2.0)
		childFaces.append(childFace)
	state = STATE.SUBDIVIDING

# Faces finished generating, so add them and hide us.
func finishSubdivision():
	for child in childFaces:
		planet.addTerrainFace(child)
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
