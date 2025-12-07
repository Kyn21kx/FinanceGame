@tool
extends EditorPlugin

# A class member to hold the dock during the plugin life cycle.

var plugin_instance : NodeComponentAdapter

func _enter_tree():
	plugin_instance = NodeComponentAdapter.new()
	print("Turning on component creator")
	add_inspector_plugin(plugin_instance)


func _exit_tree():
	remove_inspector_plugin(plugin_instance)
