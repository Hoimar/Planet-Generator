class_name MinMax

var _min_value: float setget , get_min_value
var _max_value: float setget , get_max_value
var _mutex := Mutex.new()   # MinMax instance is being accessed by all TerrainPatch threads of a TerrainContainer.


func _init():
	_min_value = INF
	_max_value = -INF


func add_value(var new: float):
	_mutex.lock()
	if new < _min_value:
		_min_value = new
	elif new > _max_value:
		_max_value = new
	_mutex.unlock()


func get_min_value() -> float:
	return _min_value


func get_max_value() -> float:
	return _max_value
