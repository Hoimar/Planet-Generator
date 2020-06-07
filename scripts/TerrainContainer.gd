tool
extends Spatial

class_name TerrainContainer

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

var faces: Array   # Stores the six basic faces that make up this planet.
var threads: Array


func _process(delta):
	var camera = get_viewport().get_camera()
	if camera:
		# Update terrain faces.
		for face in get_children():
			face.update(delta, camera.global_transform.origin)


# Generate terrain faces.
func generate(var settings: PlanetSettings, var material: Material):
	for child in get_children():
		child.queue_free()
	
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, settings, dir, material)
		addTerrainFace(face)
		threads.append(face.thread)


func addTerrainFace(var face: TerrainFace):
	add_child(face)
