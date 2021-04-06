tool
extends Spatial

export(bool) var _play_in_editor = true
export(float) var _rotation_speed := 0.2
onready var _view_position_rig := $view_position_rig
onready var _view_position := $view_position_rig/view_position
onready var _planet := $planet


func _ready():
	PGGlobals.wireframe = true
	_planet.terrain._viewer_node = _view_position


func _process(delta):
	if Engine.editor_hint and not _play_in_editor:
		return
	_view_position_rig.rotate_y(_rotation_speed*delta)
