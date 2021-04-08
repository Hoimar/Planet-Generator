class_name Logger

class Standard:
	var _context := ""
	
	
	func _init(context):
		_context = context
	
	
	func debug(msg: String):
		pass
	
	
	func warn(msg: String):
		push_warning("[WARNING] %s: %s" % [_context, msg])
	
	
	func error(msg: String):
		push_error("[ERROR] %s: %s" % [_context, msg])


class Verbose extends Standard:
	func _init(context: String).(context):
		pass
	
	
	func debug(msg: String):
		print("[DEBUG] %s: %s" % [_context , msg])


static func get_for(owner: Object) -> Standard:
	var context = owner.get_script().resource_path.get_file()
	if OS.is_stdout_verbose():
		return Verbose.new(context)
	return Standard.new(context)
