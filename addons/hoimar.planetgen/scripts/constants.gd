# Defines some constants for the quadtree and terrain patches.

const COLLISIONS_ENABLED := false   # Whether planets generate collision shapes.
const GRAVITY_ENABLED := true      # TODO: Implement gravity.
const THREADS_ENABLED := true

const GRAVITY := 0.000000981   # Increase this to make gravity fade faster than reality.
const MOUSE_SENSITIVITY := 1.5

### Quad tree and terrain LOD constants.
# Quad tree depth, also number of LOD levels.
const MAX_TREE_DEPTH := 9
# How long the feeder thread sleeps if idle in µs.
const THREAD_DELAY := 5000
# Vertex border around terrain patches.
const BORDER_SIZE := 1
# How much border vertices will be dipped in relation to patch _size.
const BORDER_DIP := 0.8
# Minimal size of quad nodes, 1/2^MAX_TREE_DEPTH
const MIN_SIZE := 1.0/pow(2, MAX_TREE_DEPTH)
# Define when LODs will be switched: min_distance * _size * radius
const MIN_DISTANCE := 4.0
# This is multiplied with theoretical noise strength to get a sane value.
const MIN_MAX_APPROXIMATION := 0.6
# The four quadrants of a quadtree leaf:
const MAX_LEAVES := 4
# Offset vector for the leaf nodes:
const LEAF_OFFSETS := [
	Vector2(-1, -1),
	Vector2(-1, 1),
	Vector2(1, -1),
	Vector2(1, 1),
]
# Normals of the six cube faces that are mapped to the planet sphere.
const DIRECTIONS: Array = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.UP,
	Vector3.DOWN,
	Vector3.LEFT,
	Vector3.RIGHT,
]
