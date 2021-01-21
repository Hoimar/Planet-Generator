class_name MinMax

var minValue: float
var maxValue: float


func _init():
	minValue = INF
	maxValue = -INF


func addValue(var new: float):
	if new < minValue:
		minValue = new
	elif new > maxValue:
		maxValue = new
