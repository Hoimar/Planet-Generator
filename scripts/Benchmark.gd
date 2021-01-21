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
	planet.get_node("terrain").set_process(false)
	add_child(planet)


func _on_Button_pressed():
	var timeBefore = OS.get_ticks_msec()
	var iterations = 10
	for i in range(0, iterations):
		planet.generate()
		yield(get_tree(), "idle_frame")
		yield(get_tree().create_timer(0.5), "timeout")
	var duration = (OS.get_ticks_msec() - timeBefore) / 1000.0
	$CanvasLayer/VBoxContainer/Label.text = "Generated terrain " + str(iterations) \
			 + " times in " + str(duration) + "s."
