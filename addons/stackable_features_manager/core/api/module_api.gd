## Module: ModuleAPI
## Purpose: Base class for all module API interfaces
## Dependencies: ModuleConfig
##

# Base class for module API interfaces
# Provides standardized methods for external interaction with modules

@tool
class_name ModuleAPI
extends RefCounted

## Reference to the module instance
var _module: FeatureModule

## Initialize the API with a module reference taking [module] [br]
## [code]ModuleAPI.new(module_instance)[/code]
func _init(module: FeatureModule = null) -> void:
	_module = module

## Returns the name of the module [br]
## [code]var name = api.get_module_name()[/code]
func get_module_name() -> String:
	if _module:
		return _module.get_module_name()
	return "unknown"

## Checks if the module reference is valid [br]
## [code]if api.is_module_valid():[/code]
func is_module_valid() -> bool:
	return _module != null

## Returns the current module configuration [br]
## [code]var config = api.get_config()[/code]
func get_config() -> ModuleConfig:
	if _module and _module.has_method("get_config"):
		return _module.config
	return null

## Sets a new configuration for the module taking [config] [br]
## [code]var success = api.set_config(new_config)[/code]
func set_config(config: ModuleConfig) -> bool:
	if not _module or not config:
		return false
	
	# Type check - ensure config matches module's expected type
	if _module.config and config.get_script() != _module.config.get_script():
		print("ModuleAPI: Invalid configuration type for module: ", get_module_name())
		return false
	
	_module.config = config
	print("ModuleAPI: Configuration updated for module: ", get_module_name())
	return true

## Merges configuration settings into the current config taking [config] [br]
## [code]var success = api.merge_config(partial_config)[/code]
func merge_config(config: ModuleConfig) -> bool:
	var current_config = get_config()
	if current_config and config and current_config.has_method("merge_config"):
		current_config.merge_config(config)
		return set_config(current_config)
	return false

## Loads a configuration preset by name taking [preset_name] [br]
## [code]var success = api.load_preset("speedrun")[/code]
func load_preset(preset_name: String) -> bool:
	# Use ModuleRegistry for common functionality
	print("ModuleAPI: Use ModuleRegistry.load_preset() instead for better performance")
	return false

## Saves the current configuration to a file taking [file_path] [br]
## [code]var success = api.save_config("user://my_config.tres")[/code]
func save_config(file_path: String) -> bool:
	# Use ModuleRegistry for common functionality
	print("ModuleAPI: Use ModuleRegistry.save_config() instead for better performance")
	return false

## Returns a list of available configuration presets [br]
## [code]var presets = api.get_available_presets()[/code]
func get_available_presets() -> Array[String]:
	# Use ModuleRegistry for common functionality
	print("ModuleAPI: Use ModuleRegistry.get_presets() instead for better performance")
	return []

## Resets the module configuration to default values [br]
## [code]var success = api.reset_to_defaults()[/code]
func reset_to_defaults() -> bool:
	# Use ModuleRegistry for common functionality
	print("ModuleAPI: Use ModuleRegistry.reset_config() instead for better performance")
	return false 