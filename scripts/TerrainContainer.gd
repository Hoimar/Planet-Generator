tool
class_name TerrainContainer
extends Spatial

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

var threadingManager := ThreadingManager.new()


func _process(delta):
	var camera = get_viewport().get_camera()
	if camera:
		# Update every terrain face.
		for face in get_children():
			face.update(delta, camera.global_transform.origin)


# Generate terrain faces.
func generate(var settings: PlanetSettings, var material: Material):
	for child in get_children():
		child.queue_free()
	
	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.init(self, settings, dir, material)


func registerTerrainFace(var face: TerrainFace):
	threadingManager.registerThread(face.thread)


# Called deferred from TerrainFace thread when it has finished.
func finishTerrainFace(var face: TerrainFace):
	threadingManager.finishThread(face.thread)
	face.set_visible(true)
	add_child(face)
