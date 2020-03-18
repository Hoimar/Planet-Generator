tool
extends WorldEnvironment

const DIRECTIONS: Array =  [Vector3.UP, Vector3.DOWN, Vector3.LEFT, Vector3.RIGHT, Vector3.FORWARD, Vector3.BACK]

export(bool) onready var generate: bool = false setget set_generate
export(int) onready var seed_value: int = 0
export(int, 3, 10000, 1) onready var resolution: int = 20 setget set_resolution

onready var planetContainer = $PlanetContainer
onready var camera = $Camera

func _ready():
	generatePlanet()

func generatePlanet():
	for child in planetContainer.get_children():
		child.queue_free()

	for dir in DIRECTIONS:
		var face: TerrainFace = TerrainFace.new()
		face.generate(planetContainer, dir, resolution, preload("res://resources/Planet.tres"))
		planetContainer.add_child(face)

func _process(delta):
	for face in planetContainer.get_children():
		face.update(delta, camera.translation)

func set_generate(var new: bool):
	generatePlanet()

func set_resolution(var new: int):
	resolution = new
	yield(self, "ready")
	generatePlanet()
