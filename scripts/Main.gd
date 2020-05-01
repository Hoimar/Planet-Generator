extends WorldEnvironment

func _ready():
	pass
	#get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME);
	#VisualServer.set_debug_generate_wireframes(true)

func _process(delta):
	$hud/VBoxContainer/lblFps.text = str("FPS: ", Engine.get_frames_per_second())
	$hud/VBoxContainer/lblSpeed.text = str("Speed: ", $Ship.currentSpeed)
	
	if Input.is_action_just_pressed("colored_faces"):
		Global.coloredFaces = !Global.coloredFaces
