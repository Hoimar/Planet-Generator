# Plugin class for Planet Generator.
tool
extends EditorPlugin

const CUSTOM_TYPE_NAME := "Solar System"
const PLUGIN_ICON := preload("resources/icons/solar-system.svg")
const SOLAR_SYSTEM_SCRIPT := preload("scripts/SolarSystem.gd")

func _enter_tree():
	var gui := get_editor_interface().get_base_control()
	add_custom_type(
		CUSTOM_TYPE_NAME,
		"Spatial",
		SOLAR_SYSTEM_SCRIPT,
		PLUGIN_ICON
	)
	add_autoload_singleton("PGGlobals", "res://addons/hoimar.planetgen/scripts/PGGlobals.gd")


func _exit_tree():
	remove_custom_type(CUSTOM_TYPE_NAME)
	remove_autoload_singleton("PGGlobals")


func get_plugin_icon() -> Texture:
	return PLUGIN_ICON
