# Experimental GUI to display basic information.
extends Node


func _ready():
	pass


func _process(_delta):
	$VBoxContainer/lblFps.text = str("FPS: ", Engine.get_frames_per_second())
	if has_node("../Ship"):
		$VBoxContainer/lblSpeed.text = str("Speed: ", round($"../Ship".currentSpeed*3500)/100, "km/s")
	checkInput()


func checkInput():
	if Input.is_action_just_pressed("toggle_colored_faces"):
		PGGlobals.coloredFaces = !PGGlobals.coloredFaces
	if Input.is_action_just_pressed("toggle_wireframe"):
		PGGlobals.wireframe = !PGGlobals.wireframe
