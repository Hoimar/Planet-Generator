extends Spatial

const PLANET: PackedScene = preload("../scenes/Planet.tscn")

var material: Resource = preload("../resources/materials/EarthlikePlanetMaterial.tres")
var settings: Resource = preload("../planetpresets/TestPlanetSettings.tres")
var planet: Planet


func _enter_tree():
	PGGlobals.benchmarkMode = true


func _exit_tree():
	PGGlobals.benchmarkMode = false


# Called when the node enters the scene tree for the first time.
func _ready():
	planet = PLANET.instance()
	planet.settings = settings
	planet.material = material
	planet.get_node("terrain").set_process(false)
	add_child(planet)


func _on_Button_pressed():
	var timeBefore = OS.get_ticks_msec()
	var iterations = 1
	var duration
	for _i in range(0, iterations):
		planet.generate()
		duration = (OS.get_ticks_msec() - timeBefore) / 1000.0
		yield(get_tree(), "idle_frame")
		yield(get_tree().create_timer(0.5), "timeout")
	$CanvasLayer/Panel/VBoxContainer/Label.text = "Generated terrain " + str(iterations) \
			 + " times in " + str(duration) + "s."
