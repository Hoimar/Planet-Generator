extends Camera3D

const MIN_WEIGHT: float = 0.05
const MAX_WEIGHT: float = 0.6

@onready
@export var target: NodePath
@export var weight: float = 0.6


func _ready():
	set_as_top_level(true)


func _physics_process(delta):
	var targetTransform: Transform3D = get_node(target).global_transform
	var distance = targetTransform.origin.distance_to(transform.origin)
	# Calculate dynamic weight.
	var dynamicWeight = max(MIN_WEIGHT, min(MAX_WEIGHT, 
			remap(distance, 0.1, 2.0, MIN_WEIGHT, MAX_WEIGHT)))
	transform = transform.interpolate_with(targetTransform, dynamicWeight)
