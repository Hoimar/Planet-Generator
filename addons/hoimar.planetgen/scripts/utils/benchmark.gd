extends Spatial
# Simple benchmark.

const Const := preload("../constants.gd")

onready var _label := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/Label
onready var _spin_box := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/SpinBox
onready var _button_benchmark := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/Button
onready var _planet := $Planet
var _duration: int


func _enter_tree():
	PGGlobals.benchmark_mode = true


func _exit_tree():
	PGGlobals.benchmark_mode = false


func _ready():
	start()


func _on_Button_pressed():
	start()


func start():
	_button_benchmark.disabled = true
	# Finish running jobs.
	_label.text = "Waiting for current jobs to finish..."
	if PGGlobals.job_queue.is_working():
		yield(PGGlobals.job_queue, "all_finished")
	# Run the actual benchmark.
	_label.text = "Benchmarking..."
	_duration = 0
	for i in _spin_box.value:
		var _tstart := OS.get_ticks_usec()
		$Planet.generate()
		yield(PGGlobals.job_queue, "all_finished")
		var _deltat = OS.get_ticks_usec() - _tstart
		_duration += _deltat
		print("Iteration %d finished in %.3fms." \
				% [i + 1, (_deltat) / 1000.0])
		yield(get_tree(), "idle_frame")
	stop()
	_button_benchmark.disabled = false


func stop():
	var text = "Generated %d times in %.3fms." \
			% [_spin_box.value, _duration / 1000.0]
	_label.text = text
	print(text)
