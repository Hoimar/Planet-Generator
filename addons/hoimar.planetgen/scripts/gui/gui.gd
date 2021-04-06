extends Node
# Experimental GUI to display basic information.

onready var lbl_fps := $VBoxContainer/LabelFps
onready var lbl_speed := $VBoxContainer/LabelSpeed
onready var ship := get_node_or_null("../Ship")



func _process(_delta):
	lbl_fps.text = str("FPS: ", Engine.get_frames_per_second())
	if ship:
		lbl_speed.text = str("Speed: ", round(ship._current_speed*3500)/100, "km/s")
	checkInput()


func checkInput():
	if Input.is_action_just_pressed("toggle_colored_patches"):
		PGGlobals.colored_patches = !PGGlobals.colored_patches
	if Input.is_action_just_pressed("toggle_wireframe"):
		PGGlobals.wireframe = !PGGlobals.wireframe
