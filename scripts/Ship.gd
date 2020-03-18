extends Spatial

# Declare member variables here. Examples:
# var a = 2
# var b = "text"

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	get_input()


func get_input():
	if Input.is_action_pressed("ui_up"):
		translate(Vector3(0, 0, -1))
	if Input.is_action_pressed("ui_down"):
		translate(Vector3(0, 0, 1))
	if Input.is_action_pressed("ui_left"):
		translate(Vector3(-1, 0, 0))
	if Input.is_action_pressed("ui_right"):
		translate(Vector3(1, 0, 0))