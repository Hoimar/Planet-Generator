extends Camera

const minWeight: float = 0.05
const maxWeight: float = 0.6

export(NodePath) onready var target
export(float) var weight: float = 0.6


func _ready():
	set_as_toplevel(true)


func _process(delta):
	var targetTransform: Transform = get_node(target).global_transform
	var distance = targetTransform.origin.distance_to(transform.origin)
	# Calculate dynamic weight.
	var dynamicWeight = max(minWeight, min(maxWeight, 
			range_lerp(distance, 0.01, 0.2, minWeight, maxWeight)))
	var label = get_tree().get_root().get_node("/root/Main/hud/VBoxContainer/lblSpeed")
	label.text += str("\n", dynamicWeight)
	transform = transform.interpolate_with(targetTransform, dynamicWeight)
