# Defines some constants the quadtree and terrain patches.

const MAX_TREE_DEPTH := 9   # Quad tree depth, also number of LOD levels.
const BORDER_SIZE := 1
const BORDER_DIP := 0.8   # How much border vertices will be dipped in relation to patch _size.
const MIN_SIZE := 1.0/pow(2, MAX_TREE_DEPTH)   # How many subdivisions are possible.
const MIN_DISTANCE := 4.0         # Define when LODs will be switched: min_distance * _size * radius
const MIN_MAX_APPROXIMATION := 0.6   # Is multiplied with theoretical noise strength to get a sane value.
# The four quadrants of a quadtree leaf:
const MAX_LEAVES := 4
const LEAF_OFFSETS := [
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1),
]
const DIRECTIONS: Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.UP,
	Vector3.DOWN,
	Vector3.LEFT,
	Vector3.RIGHT,
]
