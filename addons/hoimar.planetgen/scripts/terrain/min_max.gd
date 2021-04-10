tool
class_name MinMax


var min_value: float
var max_value: float


func _init():
	min_value = INF
	max_value = -INF


func add_value(var new: float):
	if new < min_value:
		min_value = new
	elif new > max_value:
		max_value = new

