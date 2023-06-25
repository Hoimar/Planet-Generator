@tool
extends Node3D


@export var _play_in_editor: bool = true: set = set_play_in_editor
@export var _rotation_speed: float = 0.2
@onready var _view_position_rig := $ViewPositionRig
@onready var _view_position := $ViewPositionRig/ViewPosition
@onready var _planet := $TestPlanet


func _ready():
	PGGlobals.wireframe = true
	_planet._terrain.set_viewer(_view_position)


func _process(delta):
	if Engine.is_editor_hint() and not _play_in_editor:
		return
	_view_position_rig.rotate_y(_rotation_speed*delta)


func set_play_in_editor(new: bool):
	_play_in_editor = new
	if _planet:
		_planet._terrain.set_viewer(_view_position)
