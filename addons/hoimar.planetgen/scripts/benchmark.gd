extends Spatial
# Simple benchmark. TODO: Properly calculate time to generate a set of patches.

const PLANET: PackedScene = preload("../scenes/planet.tscn")

var _material: Resource = preload("../resources/materials/earthlike_planet_material.tres")
var _settings: Resource = preload("../planet_presets/test_planet_settings.tres")
var _planet: Planet


func _enter_tree():
	PGGlobals.benchmark_mode = true


func _exit_tree():
	PGGlobals.benchmark_mode = false


# Called when the node enters the scene tree for the first time.
func _ready():
	_planet = PLANET.instance()
	_planet.settings = _settings
	_planet.material = _material
	_planet.get_node("terrain").set_process(false)
	add_child(_planet)


func _on_Button_pressed():
	var timeBefore := OS.get_ticks_usec()
	var iterations := 1
	var duration: float
	for _i in iterations:
		_planet.generate()
		duration = (OS.get_ticks_usec() - timeBefore) / 1000.0
		yield(get_tree(), "idle_frame")
		yield(get_tree().create_timer(0.5), "timeout")
	$CanvasLayer/Panel/VBoxContainer/Label.text = "Generated terrain " + str(iterations) \
			 + " times in " + str(duration) + "ms."
