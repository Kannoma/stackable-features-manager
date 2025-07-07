## Module: FeatureModule
## Purpose: Base class for all stackable feature modules
## Dependencies: None
##

# Base class that all feature modules must extend
# Provides a standardized interface for module lifecycle management

@tool
class_name FeatureModule
extends Node

## Initialize the module with typed configuration data taking [config] [br]
## [code]module.init(double_jump_config)[/code]
func init(config: ModuleConfig) -> void:
	pass

## Called when the module is ready to be used [br]
## [code]module.ready()[/code]
func ready() -> void:
	pass

## Called when the module is being unloaded [br]
## [code]module.shutdown()[/code]
func shutdown() -> void:
	pass

## Returns the name of this module [br]
## [code]var name = module.get_module_name()[/code]
func get_module_name() -> String:
	return "base_module"

## Returns the API interface for this module [br]
## [code]var api = module.get_api()[/code]
func get_api() -> ModuleAPI:
	# Override in derived classes to return specific API
	return null 