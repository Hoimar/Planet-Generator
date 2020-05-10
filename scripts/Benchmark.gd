extends Spatial

const PLANET: PackedScene = preload("res://scenes/Planet.tscn")

var material: Resource = preload("res://resources/EarthlikePlanetMaterial.tres")
var settings: Resource = preload("res://resources/TestPlanetSettings.tres")
var planet: Planet

# Called when the node enters the scene tree for the first time.
func _ready():
	planet = PLANET.instance()
	planet.settings = settings
	planet.material = material
	add_child(planet)

func _on_Button_pressed():
	for i in range(0, 10):
		planet.generate()
