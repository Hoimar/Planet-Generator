class_name MinMax

var minValue
var maxValue

func _init():
	minValue = INF
	maxValue = -INF

func addValue(var new):
	if new < minValue:
		minValue = new
	elif new > maxValue:
		maxValue = new

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
