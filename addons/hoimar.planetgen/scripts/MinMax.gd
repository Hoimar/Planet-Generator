class_name MinMax

var minValue: float
var maxValue: float
var mutex := Mutex.new()   # MinMax instance is being accessed by all TerrainFace threads of a TerrainContainer.


func _init():
	minValue = INF
	maxValue = -INF


func addValue(var new: float):
	mutex.lock()
	if new < minValue:
		minValue = new
	elif new > maxValue:
		maxValue = new
	mutex.unlock()
