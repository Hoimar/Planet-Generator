# Shift all nodes so the parent node always stays close to the center.
extends Node

const MAX_DISTANCE := 2000.0


export(NodePath) var world_node_path
onready var world_node: Spatial = get_node_or_null(world_node_path)
onready var parent := get_parent()


func _ready():
	if !world_node:
		world_node = get_node("../..")


func _process(delta):
	if parent.global_transform.origin.length() > MAX_DISTANCE:
		shift_origin()


func shift_origin():
	var offset: Vector3 = parent.global_transform.origin
	for child in world_node.get_children():
		if child is Spatial:
			child.global_translate(-offset)
