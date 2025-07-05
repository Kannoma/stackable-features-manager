## Module: ModuleRegistry
## Purpose: Singleton for clean external access to stackable feature modules
## Dependencies: ModuleManager
##
extends Node

## Required classes
# Note: Using class_name instead of preload to avoid circular dependencies

## Reference to the module manager
var _manager: ModuleManager

## Initialize the registry [br]
## [code]_ready()[/code]
func _ready() -> void:
	# Find or create the module manager
	_manager = get_node_or_null("/root/ModuleManager")
	if not _manager:
		_manager = ModuleManager.new()
		_manager.name = "ModuleManager"
		# Use call_deferred to avoid timing issues
		get_tree().root.add_child.call_deferred(_manager)
		# Wait a moment for the manager to initialize
		await get_tree().create_timer(0.1).timeout
	
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
## [code]var success = ModuleRegistry.load("jump_boost")[/code]
func load(module_name: String) -> bool:
	if not _manager:
		print("ModuleRegistry: Manager not initialized - cannot load module '", module_name, "'")
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module '", module_name, "' is disabled - cannot load")
		return false
	
	return _manager.load_module(module_name)

## Unload a module by name taking [module_name] [br]
## [code]var success = ModuleRegistry.unload("jump_boost")[/code]
func unload(module_name: String) -> bool:
	if not _manager:
		return false
	return _manager.unload_module(module_name)

## Enable or disable a module taking [module_name] and [enabled] [br]
## [code]ModuleRegistry.set_enabled("jump_boost", false)[/code]
func set_enabled(module_name: String, enabled: bool) -> bool:
	if not _manager:
		return false
	return _manager.set_module_enabled(module_name, enabled)

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

## Load a preset configuration for a module taking [module_name] and [preset_name] [br]
## [code]var success = ModuleRegistry.load_preset("jump_boost", "speedrun")[/code]
func load_preset(module_name: String, preset_name: String) -> bool:
	if not _manager:
		print("ModuleRegistry: Manager not initialized - cannot load preset '", preset_name, "' for module '", module_name, "'")
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module '", module_name, "' is disabled - cannot load preset '", preset_name, "'")
		return false
	
	return _manager.load_module_preset(module_name, preset_name)

## Save a module's current configuration taking [module_name] and [file_path] [br]
## [code]var success = ModuleRegistry.save_config("jump_boost", "user://my_config.tres")[/code]
func save_config(module_name: String, file_path: String) -> bool:
	if not _manager:
		print("ModuleRegistry: Manager not initialized - cannot save config for module '", module_name, "'")
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module '", module_name, "' is disabled - cannot save config")
		return false
	
	return _manager.save_module_config(module_name, file_path)

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
	
	return _manager.get_module_presets(module_name)

## Reset a module's configuration to defaults taking [module_name] [br]
## [code]var success = ModuleRegistry.reset_config("jump_boost")[/code]
func reset_config(module_name: String) -> bool:
	if not _manager:
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module is disabled: ", module_name)
		return false
	
	return _manager.reset_module_to_defaults(module_name)

## Merge configuration into a module's current config taking [module_name] and [config] [br]
## [code]var success = ModuleRegistry.merge_config("jump_boost", partial_config)[/code]
func merge_config(module_name: String, config: ModuleConfig) -> bool:
	if not _manager:
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module is disabled: ", module_name)
		return false
	
	return _manager.merge_module_config(module_name, config)

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
## [code]var success = ModuleRegistry.set_config("jump_boost", new_config)[/code]
func set_config(module_name: String, config: ModuleConfig) -> bool:
	if not _manager:
		return false
	
	# Check if module is enabled first
	if not _manager.is_module_enabled(module_name):
		print("ModuleRegistry: Module is disabled: ", module_name)
		return false
	
	var api = get_api(module_name)
	if api and api.has_method("set_config"):
		return api.set_config(config)
	return false 
