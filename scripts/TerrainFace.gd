# Represents one patch of terrain in the quad tree that's projected onto a sphere.

extends MeshInstance

class_name TerrainFace

# The four corners of a quad.
const OFFSETS: Array = [Vector2(-1, -1), Vector2(-1, 1), Vector2(1, -1), Vector2(1, 1)]

var container: Spatial   # Node in the scene hierarchy to contain the faces.
var axisUp: Vector3      # Normal of flat cube face.
var axisA: Vector3       # Axis perpendicular to the normal.
var axisB: Vector3       # Axis perpendicular to both above.
var resolution: int      # Subdivision level of this mesh.
var offsetA: Vector3     # Offset for every vertex to the correct "corner" on axisA.
var offsetB: Vector3     # Offset for every vertex to the correct "corner" on axisB.
var size: float          # Size of this quad. 1 is a full cube face, 0.5 a quarter etc.
var material: SpatialMaterial

var parentFace: TerrainFace   # Parent face in the quad tree.
var childFaces: Array = []    # The child faces in the quad tree.


func generate(  container: Spatial, \
				axisUp: Vector3, \
				resolution: int, \
				material: SpatialMaterial = null, \
				parentFace: TerrainFace = null, \
				offset: Vector2 = Vector2(0, 0), \
				size: float = 1):
	self.container = container
	self.parentFace = parentFace
	self.axisUp = axisUp.normalized()
	self.axisA = Vector3(axisUp.y, axisUp.z, axisUp.x) * size
	self.axisB = axisUp.cross(axisA).normalized() * size
	self.resolution = resolution
	self.offsetA = Vector3(axisA * offset.x)
	self.offsetB = Vector3(axisB * offset.y)
	self.size = size
	self.material = material
	createMesh()

func update(delta, var viewPosition: Vector3):
	if Input.is_key_pressed(KEY_SPACE): #camera is too close:
		subdivide()


func createMesh():
	var vertices: PoolVector3Array = PoolVector3Array()
	vertices.resize(resolution*resolution)
	var triangles = PoolIntArray()
	triangles.resize((resolution - 1) * (resolution - 1) * 6);
	
	# Build the mesh.
	var triIndex: int = 0;
	for y in range(0, resolution):
		for x in range(0, resolution):
			# Calculate position of this vertex.
			var vertexIdx: int = y + x * resolution;
			var percent: Vector2 = Vector2(x, y) / (resolution - 1);
			var pointOnUnitCube: Vector3 = axisUp \
										+ (percent.x - .5) * 2.0 * axisA \
										+ (percent.y - .5) * 2.0 * axisB \
										+ offsetA \
										+ offsetB;
			var pointOnUnitSphere: Vector3 = pointOnUnitCube.normalized();
			vertices[vertexIdx] = pointOnUnitSphere;
			
			# Build two triangles that form one quad of this face.
			if x != resolution - 1 && y != resolution - 1:
				triangles[triIndex] = vertexIdx;
				triangles[triIndex + 1] = vertexIdx + resolution + 1;
				triangles[triIndex + 2] = vertexIdx + resolution;
				
				triangles[triIndex + 3] = vertexIdx;
				triangles[triIndex + 4] = vertexIdx + 1;
				triangles[triIndex + 5] = vertexIdx + resolution + 1;
				triIndex += 6;
	
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
		var norm = -(v2 - v1).normalized().cross((v3 - v1).normalized()).normalized()
		
		normals[vertexIdx1] = norm
		normals[vertexIdx2] = norm
		normals[vertexIdx2] = norm
	
	# Commit the mesh.
	var arrays = Array()
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = triangles
	mesh = ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	mesh.surface_set_material(0, material)

# Subdivide this face into four smaller ones.
func subdivide():
	for offset in OFFSETS:
		var childFace: TerrainFace = get_script().new()
		childFace.generate(container, axisUp, resolution, material, self, offset, size/2.0)
		container.add_child(childFace)
	set_visible(false)


func merge():
	queue_free()
	set_visible(false)
