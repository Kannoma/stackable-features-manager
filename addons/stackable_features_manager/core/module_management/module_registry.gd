## Module: ModuleRegistry
## Purpose: Singleton for clean external access to stackable feature modules
## Dependencies: ModuleManager, ServiceLocator
##
extends Node

## Required classes
# Note: Using class_name instead of preload to avoid circular dependencies

## Reference to the module manager
var _manager: ModuleManager

## Initialize the registry [br]
## [code]_ready()[/code]
func _ready() -> void:
	# Create the module manager directly instead of searching for it
	_manager = ModuleManager.new()
	_manager.name = "ModuleManager"
	add_child(_manager)
	
	# Register manager in service locator
	ServiceLocator.get_instance().register("ModuleManager", _manager)
	
	# Wait for manager to be ready
	if not _manager.is_node_ready():
		await _manager.ready
	
	print("ModuleRegistry: Initialized and ready")

## Get a module's API interface for module-specific functions taking [module_name] [br]
## [code]var jumpboost = ModuleRegistry.get_api("jump_boost")[/code]
func get_api(module_name: String) -> Variant:
	# Always return a SafeAPIWrapper - never null or raw API
	if not _manager:
		# Manager not initialized - return safe wrapper for disabled module
		return SafeAPIWrapper.new(module_name, null, false)
	
	# Check if module is enabled
	if not _manager.is_module_enabled(module_name):
		# Module disabled - return safe wrapper for disabled module
		return SafeAPIWrapper.new(module_name, null, false)
	
	var api = _manager.get_module_api(module_name)
	if not api:
		# Module not found or not loaded - return safe wrapper for disabled module
		return SafeAPIWrapper.new(module_name, null, false)
	
	# Module is enabled and API exists - return safe wrapper for enabled module
	return SafeAPIWrapper.new(module_name, api, true)

## Create a safe API with bulletproof error handling [br]
## [code]var api = _create_safe_api("jump_boost")[/code]
func _create_safe_api(module_name: String) -> Variant:
	# Try to create NullSafeAPI first
	var null_api = NullSafeAPI.new(module_name)
	
	# Verify it was created successfully
	if null_api == null:
		# Use UniversalSafeAPI as ultimate fallback
		var universal_api = UniversalSafeAPI.new(module_name)
		return universal_api
	
	return null_api

## Get the raw module instance (advanced usage) taking [module_name] [br]
## [code]var module = ModuleRegistry.get_module("jump_boost")[/code]
func get_module(module_name: String) -> FeatureModule:
	if not _manager:
		print("ModuleRegistry: Manager not initialized - cannot get module '", module_name, "'")
		return null
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module '", module_name, "' is disabled - cannot get module instance")
		return null
	
	return _manager.get_module(module_name)

## Check if a module is currently loaded taking [module_name] [br]
## [code]if ModuleRegistry.is_loaded("jump_boost"):[/code]
func is_loaded(module_name: String) -> bool:
	if not _manager:
		return false
	return _manager.is_module_loaded(module_name)

## Load a module by name taking [module_name] [br]
## [code]var result = ModuleRegistry.load("jump_boost")[/code]
func load(module_name: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot load module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot load")
	
	var success = _manager.load_module(module_name)
	if success:
		return Result.success("Module '" + module_name + "' loaded successfully")
	else:
		return Result.failure("Failed to load module '" + module_name + "'")

## Unload a module by name taking [module_name] [br]
## [code]var result = ModuleRegistry.unload("jump_boost")[/code]
func unload(module_name: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot unload module '" + module_name + "'")
	
	var success = _manager.unload_module(module_name)
	if success:
		return Result.success("Module '" + module_name + "' unloaded successfully")
	else:
		return Result.failure("Failed to unload module '" + module_name + "'")

## Enable or disable a module taking [module_name] and [enabled] [br]
## [code]var result = ModuleRegistry.set_enabled("jump_boost", false)[/code]
func set_enabled(module_name: String, enabled: bool) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot set module state for '" + module_name + "'")
	
	var success = _manager.set_module_enabled(module_name, enabled)
	if success:
		var action = "enabled" if enabled else "disabled"
		return Result.success("Module '" + module_name + "' " + action + " successfully")
	else:
		return Result.failure("Failed to set enabled state for module '" + module_name + "'")

## Check if a module is enabled taking [module_name] [br]
## [code]if ModuleRegistry.is_enabled("jump_boost"):[/code]
func is_enabled(module_name: String) -> bool:
	if not _manager:
		return false
	return _manager.is_module_enabled(module_name)

## Get list of all available modules [br]
## [code]var modules = ModuleRegistry.get_available_modules()[/code]
func get_available_modules() -> Dictionary:
	if not _manager:
		return {}
	return _manager.get_available_modules()

## Get list of currently loaded modules [br]
## [code]var loaded = ModuleRegistry.get_loaded_modules()[/code]
func get_loaded_modules() -> Dictionary:
	if not _manager:
		return {}
	return _manager.get_loaded_modules()

# =============================================================================
# COMMON CONFIGURATION FUNCTIONS (No need to duplicate in APIs!)
# =============================================================================

## Load a preset configuration for a module taking [module_name] and [preset_name_or_path] [br]
## [code]var result = ModuleRegistry.load_preset("jump_boost", "speedrun")[/code] for internal preset [br]
## [code]var result = ModuleRegistry.load_preset("jump_boost", "res://my_custom_preset.tres")[/code] for external preset
func load_preset(module_name: String, preset_name_or_path: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot load preset '" + preset_name_or_path + "' for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot load preset '" + preset_name_or_path + "'")
	
	# Smart detection: if it contains "/" or ends with ".tres", treat as external file path
	if preset_name_or_path.contains("/") or preset_name_or_path.ends_with(".tres"):
		# External preset - use FeatureConfig to load from any location
		var config = FeatureConfig.load_any_preset(preset_name_or_path, module_name)
		if config:
			# Apply the loaded config to the module
			var api = _manager.get_module_api(module_name)
			if api and api.has_method("set_config"):
				if api.set_config(config):
					return Result.success("External preset '" + preset_name_or_path + "' loaded successfully for module '" + module_name + "'")
				else:
					return Result.failure("Failed to apply external preset '" + preset_name_or_path + "' to module '" + module_name + "'")
			else:
				return Result.failure("Module '" + module_name + "' does not support config setting")
		else:
			return Result.failure("Failed to load external preset '" + preset_name_or_path + "' for module '" + module_name + "' - file may not exist or be invalid")
	else:
		# Internal preset - use automatic preset loading via FeatureConfig
		var module_path = "res://stackable_features/" + module_name
		var config = FeatureConfig.load_module_preset(module_path, preset_name_or_path)
		if config:
			# Apply the loaded config to the module
			var api = _manager.get_module_api(module_name)
			if api and api.has_method("set_config"):
				if api.set_config(config):
					return Result.success("Internal preset '" + preset_name_or_path + "' loaded successfully for module '" + module_name + "'")
				else:
					return Result.failure("Failed to apply internal preset '" + preset_name_or_path + "' to module '" + module_name + "'")
			else:
				return Result.failure("Module '" + module_name + "' does not support config setting")
		else:
			return Result.failure("Failed to load internal preset '" + preset_name_or_path + "' for module '" + module_name + "' - preset may not exist")

## Save a module's current configuration taking [module_name] and [file_path] [br]
## [code]var result = ModuleRegistry.save_config("jump_boost", "user://my_config.tres")[/code]
func save_config(module_name: String, file_path: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot save config for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot save config")
	
	var success = _manager.save_module_config(module_name, file_path)
	if success:
		return Result.success("Configuration saved successfully for module '" + module_name + "' to '" + file_path + "'")
	else:
		return Result.failure("Failed to save configuration for module '" + module_name + "'")

## Get available presets for a module taking [module_name] [br]
## [code]var presets = ModuleRegistry.get_presets("jump_boost")[/code]
func get_presets(module_name: String) -> Array[String]:
	if not _manager:
		print("ModuleRegistry: Manager not initialized - returning empty presets list for module '", module_name, "'")
		return []
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		# Silent handling - return empty array for disabled modules
		return []
	
	# Use automatic preset discovery via FeatureConfig
	var module_path = "res://stackable_features/" + module_name
	return FeatureConfig.get_module_presets(module_path)

## Reset a module's configuration to defaults taking [module_name] [br]
## [code]var result = ModuleRegistry.reset_config("jump_boost")[/code]
func reset_config(module_name: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot reset config for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot reset config")
	
	var success = _manager.reset_module_to_defaults(module_name)
	if success:
		return Result.success("Configuration reset to defaults for module '" + module_name + "'")
	else:
		return Result.failure("Failed to reset configuration for module '" + module_name + "'")

## Merge configuration into a module's current config taking [module_name] and [config] [br]
## [code]var result = ModuleRegistry.merge_config("jump_boost", partial_config)[/code]
func merge_config(module_name: String, config: ModuleConfig) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot merge config for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot merge config")
	
	var success = _manager.merge_module_config(module_name, config)
	if success:
		return Result.success("Configuration merged successfully for module '" + module_name + "'")
	else:
		return Result.failure("Failed to merge configuration for module '" + module_name + "'")

## Get a module's current configuration taking [module_name] [br]
## [code]var config = ModuleRegistry.get_config("jump_boost")[/code]
func get_config(module_name: String) -> ModuleConfig:
	if not _manager:
		return null
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module is disabled: ", module_name)
		return null
	
	var api = get_api(module_name)
	if api and api.has_method("get_config"):
		return api.get_config()
	return null

## Set a module's configuration taking [module_name] and [config] [br]
## [code]var result = ModuleRegistry.set_config("jump_boost", new_config)[/code]
func set_config(module_name: String, config: ModuleConfig) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot set config for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot set config")
	
	var api = get_api(module_name)
	if api and api.has_method("set_config"):
		var success = api.set_config(config)
		if success:
			return Result.success("Configuration set successfully for module '" + module_name + "'")
		else:
			return Result.failure("Failed to set configuration for module '" + module_name + "'")
	else:
		return Result.failure("Module '" + module_name + "' does not support configuration setting")

## Load a preset from any location (internal or external file) taking [module_name] and [preset_path_or_name] [br]
## [code]var result = ModuleRegistry.load_any_preset("jump_boost", "res://my_custom_preset.tres")[/code]
func load_any_preset(module_name: String, preset_path_or_name: String) -> Result:
	if not _manager:
		return Result.failure("ModuleRegistry: Manager not initialized - cannot load preset '" + preset_path_or_name + "' for module '" + module_name + "'")
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		return Result.failure("ModuleRegistry: Module '" + module_name + "' is disabled - cannot load preset '" + preset_path_or_name + "'")
	
	# Use FeatureConfig to load from any location
	var config = FeatureConfig.load_any_preset(preset_path_or_name, module_name)
	if config:
		# Apply the loaded config to the module
		var api = _manager.get_module_api(module_name)
		if api and api.has_method("set_config"):
			if api.set_config(config):
				return Result.success("Preset '" + preset_path_or_name + "' loaded successfully for module '" + module_name + "'")
			else:
				return Result.failure("Failed to apply preset '" + preset_path_or_name + "' to module '" + module_name + "'")
		else:
			return Result.failure("Module '" + module_name + "' does not support config setting")
	else:
		return Result.failure("Failed to load preset '" + preset_path_or_name + "' for module '" + module_name + "' - file may not exist or be invalid")

## Load an external preset file taking [module_name] and [file_path] [br]
## [code]var result = ModuleRegistry.load_external_preset("jump_boost", "res://my_custom_preset.tres")[/code]
func load_external_preset(module_name: String, file_path: String) -> Result:
	return load_any_preset(module_name, file_path) 
