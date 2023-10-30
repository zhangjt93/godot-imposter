@tool
extends EditorPlugin
var plugin = preload("res://addons/Imposter/imposter.tscn").instantiate()

func _enter_tree():
	# Initialization of the plugin goes here.
	add_control_to_bottom_panel(plugin,"imposter")


func _exit_tree():
	# Clean-up of the plugin goes here.
	remove_control_from_bottom_panel(plugin)
	plugin.queue_free()
