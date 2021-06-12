tool
class_name QuadNode

# One quadrant in a quadtree.
# Lifecycle looks like one of these:
# 1. PREPARING → WAITING → ACTIVE → SPLITTING → SPLIT → ACTIVE → MAY_MERGE.
# 2. PREPARING → WAITING → ACTIVE → MAY_MERGE.
# 3. PREPARING → MAY_MERGE.
# 4. PREPARING → WAITING → MAY_MERGE.

const Const := preload("../constants.gd")

enum STATE {PREPARING, WAITING, ACTIVE, SPLITTING, SPLIT, MAY_MERGE}

var parent: QuadNode
var depth: int
var leaves: Array
var terrain: MeshInstance   # Terrain patch in this quadtree node.
var terrain_job: TerrainJob
var _state: int = STATE.PREPARING
var _size: float   # Size of this quad, 1/depth
var _terrain_manager: Spatial
var _center: Vector3   # Position of the center.
var _min_distance: float   # Distance to viewer at which this node subdivides.
var _viewer_node: Spatial setget set_viewer


func _init(var parent: QuadNode, var direction: Vector3, \
			var terrain_manager: Spatial, var leaf_index := -1):
	var offset: Vector2
	if not parent:
		# We're the top level quadtree node.
		depth = 1
		_size = 1.0
		offset = Vector2(0, 0)
	else:
		# Spawning as a leaf node, so use an offset.
		self.parent = parent
		depth = parent.depth + 1
		_size = parent._size / 2
		_viewer_node = parent._viewer_node
		offset = Const.LEAF_OFFSETS[leaf_index]
	var data := PatchData.new(terrain_manager, self, direction, offset)
	_terrain_manager = terrain_manager
	_center = data.center
	_min_distance = Const.MIN_DISTANCE * _size * data.settings.radius
	terrain_job = PGGlobals.queue_terrain_patch(data)
	terrain_job.connect("job_finished", self, "on_patch_finished", [], CONNECT_DEFERRED)


# Update this node in the quadtree.
func visit():
	var distance: float = _viewer_node.global_transform.origin.distance_to(_terrain_manager.global_transform.origin + _center)
	var viewer_in_range: bool = distance < _min_distance
	if _state == STATE.ACTIVE or _state == STATE.MAY_MERGE:
		if viewer_in_range:
			split_start()
		elif _state != STATE.MAY_MERGE:
			mark_redundant()
	elif _state == STATE.SPLIT:
		if not viewer_in_range:
			var can_merge: bool = true
			for leaf in leaves:
				if leaf._state != STATE.MAY_MERGE:
					can_merge = false
			if can_merge:
				merge()
	elif _state == STATE.SPLITTING:
		if viewer_in_range:
			var split_finished: bool = true
			for leaf in leaves:
				if leaf._state == STATE.PREPARING:
					split_finished = false
			if split_finished:
				split_finish()
		else:
			# Viewer has left range while in the process of splitting.
			merge()


# Begin splitting this node up into leaf nodes.
func split_start():
	if depth == Const.MAX_TREE_DEPTH:
		return   # Don't split any further.
	for i in Const.MAX_LEAVES:
		# Workaround for cyclic reference issues.
		leaves.append(
				get_script().new(self, terrain.data.axis_up, _terrain_manager, i)
		)
	_state = STATE.SPLITTING


# Leaf nodes are done generating and ready to go.
func split_finish():
	for leaf in leaves:
		leaf.on_ready_to_show()
	terrain.set_visible(false)
	_state = STATE.SPLIT


func merge():
	for leaf in leaves:
		leaf.destroy()
	leaves.clear()
	terrain.set_visible(true)
	_state = STATE.ACTIVE


func mark_redundant():
	if not parent:
		return
	_state = STATE.MAY_MERGE


# Destroys this node, also handles being destroyed while job is running.
func destroy():
	if terrain_job:
		terrain_job.abort()
	if terrain:
		terrain.queue_free()


# TerrainPatch for this node is done.
func on_patch_finished(var job: TerrainJob, var patch: TerrainPatch):
	terrain = patch
	terrain_job = null
	if parent:
		# Signal to parent that we're wait for sibling nodes to finish.
		_state = STATE.WAITING
	else:
		# Top level node, don't wait for siblings.
		on_ready_to_show()


func on_ready_to_show():
	assert(terrain_job == null, "Terrain job for %s is not done!" % str(self))
	terrain.set_visible(true)
	_terrain_manager.add_child(terrain)
	_state = STATE.ACTIVE
	if not _viewer_node:
		set_viewer(terrain.get_viewport().get_camera())


func get_num_children() -> int:
	var result: int
	for leaf in leaves:
		result += leaf.get_num_children()
	return result


func set_viewer(var viewer: Spatial):
	_viewer_node = viewer
	for leaf in leaves:
		leaf.set_viewer(viewer)
