## Module: StackableFeaturesManager
## Purpose: Main plugin script for the Stackable Features Manager
## Dependencies: ModuleManagerDock
##

# Main plugin script for the Stackable Features Manager
# Handles plugin lifecycle and editor integration

@tool
extends EditorPlugin

## Constants - using proper paths for new structure
const DOCK_SCENE = preload("res://addons/stackable_features_manager/ui/module_manager_dock.tscn")

## Plugin variables
var dock_instance

## Called when the plugin is enabled [br]
## [code]_enter_tree()[/code]
func _enter_tree() -> void:
	# Ensure stackable_features directory exists
	ensure_stackable_features_directory()
	
	# Add ModuleRegistry as autoload with correct path
	add_autoload_singleton("ModuleRegistry", "res://addons/stackable_features_manager/core/module_management/module_registry.gd")
	
	# Create and add the dock
	dock_instance = DOCK_SCENE.instantiate()
	add_control_to_dock(DOCK_SLOT_LEFT_BR, dock_instance)
	
	print("Stackable Features Manager: Plugin enabled")

## Called when the plugin is disabled [br]
## [code]_exit_tree()[/code]
func _exit_tree() -> void:
	# Remove the dock
	if dock_instance:
		remove_control_from_docks(dock_instance)
		dock_instance.queue_free()
		dock_instance = null
	
	# Remove ModuleRegistry autoload
	remove_autoload_singleton("ModuleRegistry")
	
	print("Stackable Features Manager: Plugin disabled")

## Ensure the stackable_features directory exists [br]
## [code]ensure_stackable_features_directory()[/code]
func ensure_stackable_features_directory() -> void:
	var stackable_features_path = "res://stackable_features"
	if not DirAccess.dir_exists_absolute(stackable_features_path):
		var dir = DirAccess.open("res://")
		if dir.make_dir("stackable_features") == OK:
			print("Stackable Features Manager: Created stackable_features directory")
		else:
			print("Stackable Features Manager: Failed to create stackable_features directory")
