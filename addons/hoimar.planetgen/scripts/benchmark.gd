extends Spatial
# Simple benchmark. TODO: Properly calculate time to generate a set of patches.


func _enter_tree():
	PGGlobals.benchmark_mode = true


func _exit_tree():
	PGGlobals.benchmark_mode = false


func _on_Button_pressed():
	var timeBefore := OS.get_ticks_usec()
	var iterations := 1
	var duration: float
	for _i in iterations:
		$Planet.generate()
		duration = (OS.get_ticks_usec() - timeBefore) / 1000.0
	$CanvasLayer/Panel/VBoxContainer/Label.text = \
			"Generated terrain %d times in %dms." % [iterations, duration]
