extends Spatial
# Simple benchmark.

onready var _label := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/Label
onready var _spin_box := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/HBoxContainer/SpinBox
onready var _button_benchmark := $CanvasLayer/Control/Panel/MarginContainer/VBoxContainer/Button
onready var _planet := $Planet
var _start_time: int


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
	if $Planet._terrain.job_pool.is_working():
		# Finish running jobs.
		_label.text = "Waiting for current jobs to finish..."
		while $Planet._terrain.job_pool.is_working():
			yield(get_tree(), "idle_frame")
	# Run the actual benchmark.
	_label.text = "Benchmarking..."
	_start_time = OS.get_ticks_usec()
	for i in _spin_box.value:
		var _iteration_start := OS.get_ticks_usec()
		$Planet.generate()
		while $Planet._terrain.job_pool.is_working():
			$Planet._terrain.job_pool.process_queue()
		var duration := (OS.get_ticks_usec() - _iteration_start) / 1000.0
		print("Iteration %d finished in %.3fms." % [i+1, duration])
		yield(get_tree(), "idle_frame")
	stop()
	_button_benchmark.disabled = false


func stop():
	var duration := (OS.get_ticks_usec() - _start_time) / 1000.0
	var text = "Generated %d times in %.3fms." % [_spin_box.value, duration]
	_label.text = text
	print(text)

