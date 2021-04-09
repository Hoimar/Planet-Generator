extends Spatial
# Simple benchmark. TODO: Properly calculate time to generate a set of patches.

enum STATE {RUNNING, STOPPED}

onready var _label := $CanvasLayer/Panel/VBoxContainer/Label
var _state: int
var _start_time: int


func _enter_tree():
	PGGlobals.benchmark_mode = true


func _exit_tree():
	PGGlobals.benchmark_mode = false


func _ready():
	start()


func _process(_delta):
	if _state == STATE.RUNNING and $Planet._terrain.job_pool.get_number_of_jobs() == 0:
		stop()


func _on_Button_pressed():
	start()


func start():
	_state = STATE.RUNNING
	_label.text = "Benchmarking..."
	_start_time = OS.get_ticks_usec()
	$Planet.generate()


func stop():
	_state = STATE.STOPPED
	var duration := (OS.get_ticks_usec() - _start_time) / 1000.0
	_label.text = \
			"Generated terrain in %dms." % duration

