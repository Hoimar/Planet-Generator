extends Camera

const MIN_WEIGHT: float = 0.05
const MAX_WEIGHT: float = 0.6

export(NodePath) onready var target
export(float) var weight: float = 0.6


func _ready():
	set_as_toplevel(true)


func _physics_process(delta):
	var targetTransform: Transform = get_node(target).global_transform
	var distance = targetTransform.origin.distance_to(transform.origin)
	# Calculate dynamic weight.
	var dynamicWeight = max(MIN_WEIGHT, min(MAX_WEIGHT, 
			range_lerp(distance, 0.1, 2.0, MIN_WEIGHT, MAX_WEIGHT)))
	transform = transform.interpolate_with(targetTransform, dynamicWeight)
