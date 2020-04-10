extends WorldEnvironment

var t = Thread.new()

func _ready():
	pass
	#get_viewport().set_debug_draw(Viewport.DEBUG_DRAW_WIREFRAME);
	#VisualServer.set_debug_generate_wireframes(true)

func _process(delta):
	$hud/lblFps.text = str("FPS: ", Engine.get_frames_per_second())
	
	if Input.is_action_just_pressed("colored_faces"):
		Global.coloredFaces = !Global.coloredFaces
