extends WorldEnvironment

func _ready():
	pass
	#get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME);
	#VisualServer.set_debug_generate_wireframes(true)

func _process(delta):
	if Input.is_action_just_pressed("colored_faces"):
		Global.coloredFaces = !Global.coloredFaces
