extends Node
# Experimental GUI to display some debug information, uses ugly private member access for now.

onready var lbl_status := $Root/MarginContainer/HBoxContainer/LabelStatus
onready var lbl_speedscale := $Root/MarginContainer/HBoxContainer/Control/LabelSpeedScale
onready var slider_speedscale := $Root/MarginContainer/HBoxContainer/Control/HSlider 
onready var ship : Spatial = get_tree().get_nodes_in_group("player")[0]


func _ready():
	ship.connect("speed_scale_changed", self, "update_speed_scale")


func _process(_delta):
	lbl_status.text = "FPS: %d" % Engine.get_frames_per_second()
	lbl_status.text += "\nwireframe: %s\ncolored_patches: %s" \
			% [PGGlobals.wireframe, PGGlobals.colored_patches]
	if ship:
		if ship.get("_current_speed"):
			lbl_status.text += "\nspeed: %f km/s" % (round(ship._current_speed*3500)/100)
		if ship.get("linear_velocity"):
			lbl_status.text += "\nvelocity: %s" % ship.linear_velocity
	show_planet_info()
	check_input()


func show_planet_info():
	if PGGlobals.solar_systems.empty():
		return
	var num_jobs: int = PGGlobals.job_queue.get_number_of_jobs()
	lbl_status.text += "\nTerrain patch queue size: %d" % num_jobs
	for planet in PGGlobals.solar_systems[0]._all_planets:
		lbl_status.text += "\n%s%s  |  %d patches" % \
				[planet.name, str(planet), planet._terrain.get_children().size()]


func check_input():
	if Input.is_action_just_pressed("toggle_colored_patches"):
		PGGlobals.colored_patches = !PGGlobals.colored_patches
	if Input.is_action_just_pressed("toggle_wireframe"):
		PGGlobals.wireframe = !PGGlobals.wireframe


func _on_HSlider_value_changed(value):
	lbl_speedscale.text = str(value)
	ship.speed_scale = value


func update_speed_scale(value):
	slider_speedscale.value = value
