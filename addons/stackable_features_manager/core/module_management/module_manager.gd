## Module: ModuleManager
## Purpose: Central manager for loading and managing stackable feature modules
## Dependencies: FeatureModule, FeatureConfig, ManifestLoader
##

# Singleton class for managing feature modules
# Handles discovery, loading, and lifecycle of modules

@tool
class_name ModuleManager
extends Node

## Signals
signal module_loaded(module_name: String)
signal module_unloaded(module_name: String)
signal modules_refreshed()

## Constants
const FEATURES_FOLDER = "stackable_features"
const SETTINGS_FILE_PATH = "stackable_features/features_state.sfm"

## Private variables
var _loaded_modules: Dictionary = {}
var _available_modules: Dictionary = {}
var _module_states: Dictionary = {}

## Initialize the module manager
## [code]_ready()[/code]
func _ready() -> void:
	print("ModuleManager: Initializing...")
	refresh_available_modules()
	print("ModuleManager: Ready - ", _available_modules.size(), " modules available")

## Load module enabled/disabled states from persistent storage in SFM format
## [code]module_manager.load_settings()[/code]
func load_settings() -> void:
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.READ)
	if not file:
		print("ModuleManager: No settings file found, using defaults")
		return
	
	var content = file.get_as_text()
	file.close()
	
	# Remove comment lines (lines starting with #)
	var lines = content.split("\n")
	var json_lines = []
	for line in lines:
		if not line.strip_edges().begins_with("#") and line.strip_edges() != "":
			json_lines.append(line)
	
	var json_string = "\n".join(json_lines)
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("ModuleManager: Failed to parse SFM settings file")
		return
	
	var data = json.data
	if data.has("module_states"):
		_module_states = data.module_states
		var format_info = ""
		if data.has("format") and data.has("version"):
			format_info = " (" + data.format + " v" + data.version + ")"
		print("ModuleManager: Loaded settings for ", _module_states.size(), " modules", format_info)

## Save module enabled/disabled states to persistent storage in SFM format
## [code]module_manager.save_settings()[/code]
func save_settings() -> void:
	var timestamp = Time.get_datetime_string_from_system()
	var data = {
		"format": "Stackable Features Manager State File",
		"version": "1.0",
		"generated": timestamp,
		"project": ProjectSettings.get_setting("application/config/name", "Unknown Project"),
		"module_states": _module_states
	}
	
	var json_string = JSON.stringify(data, "\t")  # Pretty print with tabs
	var file = FileAccess.open(SETTINGS_FILE_PATH, FileAccess.WRITE)
	if not file:
		print("ModuleManager: Failed to save settings file")
		return
	
	# Add custom header comment
	file.store_line("# Stackable Features Manager State File (.sfm)")
	file.store_line("# This file stores the enabled/disabled states of your stackable features")
	file.store_line("# Generated automatically - you can edit this file if needed")
	file.store_line("")
	file.store_string(json_string)
	file.close()
	print("ModuleManager: Settings saved to ", SETTINGS_FILE_PATH)

## Check if a module is enabled (defaults to true for new modules) taking [module_name]
## [code]if module_manager.is_module_enabled("double_jump"):[/code]
func is_module_enabled(module_name: String) -> bool:
	return _module_states.get(module_name, true)  # Default to enabled

## Enable or disable a module and persist the state taking [module_name] and [enabled]
## [code]module_manager.set_module_enabled("double_jump", false)[/code]
func set_module_enabled(module_name: String, enabled: bool) -> bool:
	if not module_name in _available_modules:
		print("ModuleManager: Module not found: ", module_name)
		return false
	
	_module_states[module_name] = enabled
	save_settings()
	
	if enabled:
		if not is_module_loaded(module_name):
			return load_module(module_name)
		return true
	else:
		if is_module_loaded(module_name):
			return unload_module(module_name)
		return true

## Automatically load all modules that are enabled
## [code]module_manager.auto_load_enabled_modules()[/code]
func auto_load_enabled_modules() -> void:
	var loaded_count = 0
	for module_name in _available_modules:
		if is_module_enabled(module_name):
			if not is_module_loaded(module_name):
				if load_module(module_name):
					loaded_count += 1
	if loaded_count > 0:
		print("ModuleManager: Auto-loaded ", loaded_count, " enabled modules")

## Scans the stackable_features folder for available modules
## [code]module_manager.refresh_available_modules()[/code]
func refresh_available_modules() -> void:
	_available_modules.clear()
	
	var features_dir = DirAccess.open(FEATURES_FOLDER)
	if not features_dir:
		print("ModuleManager: Features folder not found: ", FEATURES_FOLDER)
		return
	
	features_dir.list_dir_begin()
	var folder_name = features_dir.get_next()
	
	while folder_name != "":
		if features_dir.current_is_dir() and not folder_name.begins_with("."):
			var module_path = FEATURES_FOLDER + "/" + folder_name
			
			# Use ManifestLoader to load simplified JSON manifest
			var config = ManifestLoader.load_manifest(module_path)
			if config and config.is_valid():
				_available_modules[config.id] = {
					"config": config,
					"path": module_path
				}
				print("ModuleManager: Found module: ", config.id, " (", config.name, ")")
		
		folder_name = features_dir.get_next()
	
	features_dir.list_dir_end()
	print("ModuleManager: Found ", _available_modules.size(), " modules total")
	
	# Load settings and cleanup non-existent modules
	load_settings()
	cleanup_module_states()
	auto_load_enabled_modules()
	
	modules_refreshed.emit()

## Remove non-existent modules from the state and save updated state
## [code]module_manager.cleanup_module_states()[/code]
func cleanup_module_states() -> void:
	var modules_to_remove = []
	var cleanup_count = 0
	
	# Find modules in state that are no longer available
	for module_name in _module_states:
		if not module_name in _available_modules:
			modules_to_remove.append(module_name)
	
	# Remove non-existent modules from state
	for module_name in modules_to_remove:
		_module_states.erase(module_name)
		cleanup_count += 1
		print("ModuleManager: Removed non-existent module from state: ", module_name)
	
	# Save updated state if any modules were removed
	if cleanup_count > 0:
		save_settings()
		print("ModuleManager: Cleaned up ", cleanup_count, " non-existent modules from state")

## Returns a dictionary of available modules
## [code]var modules = module_manager.get_available_modules()[/code]
func get_available_modules() -> Dictionary:
	return _available_modules

## Loads a specific module by name taking [module_name]
## [code]var success = module_manager.load_module("double_jump")[/code]
func load_module(module_name: String) -> bool:
	if module_name in _loaded_modules:
		print("ModuleManager: Module already loaded: ", module_name)
		return true
	
	if not module_name in _available_modules:
		print("ModuleManager: Module not found: ", module_name)
		return false
	
	var module_info = _available_modules[module_name]
	var config = module_info.config
	var module_path = module_info.path
	
	# Load the entry script
	var script_path = config.get_entry_script_path(module_path)
	if not FileAccess.file_exists(script_path):
		print("ModuleManager: Entry script not found: ", script_path)
		return false
	
	var script = load(script_path)
	if not script:
		print("ModuleManager: Failed to load script: ", script_path)
		return false
	
	# Create module instance
	var module_instance = script.new()
	if not module_instance or not module_instance.has_method("init"):
		print("ModuleManager: Module does not extend FeatureModule: ", module_name)
		return false
	
	# Initialize and add to tree
	add_child(module_instance)
	module_instance.init(config.get_config())
	module_instance.ready()
	
	_loaded_modules[module_name] = {
		"instance": module_instance,
		"config": config
	}
	
	print("ModuleManager: Module loaded successfully: ", module_name)
	module_loaded.emit(module_name)
	return true

## Unloads a specific module by name taking [module_name]
## [code]var success = module_manager.unload_module("double_jump")[/code]
func unload_module(module_name: String) -> bool:
	if not module_name in _loaded_modules:
		print("ModuleManager: Module not loaded: ", module_name)
		return false
	
	var module_info = _loaded_modules[module_name]
	var module_instance = module_info.instance
	
	module_instance.shutdown()
	remove_child(module_instance)
	module_instance.queue_free()
	
	_loaded_modules.erase(module_name)
	
	print("ModuleManager: Module unloaded: ", module_name)
	module_unloaded.emit(module_name)
	return true

## Returns a dictionary of currently loaded modules
## [code]var loaded = module_manager.get_loaded_modules()[/code]
func get_loaded_modules() -> Dictionary:
	return _loaded_modules

## Checks if a module is currently loaded taking [module_name]
## [code]if module_manager.is_module_loaded("double_jump"):[/code]
func is_module_loaded(module_name: String) -> bool:
	return module_name in _loaded_modules

## Gets a loaded module instance by name taking [module_name]
## [code]var module = module_manager.get_module("double_jump")[/code]
func get_module(module_name: String) -> Node:
	if module_name in _loaded_modules:
		return _loaded_modules[module_name].instance
	return null

## Gets the API interface for a loaded module taking [module_name]
## [code]var api = module_manager.get_module_api("double_jump")[/code]
func get_module_api(module_name: String) -> ModuleAPI:
	var module = get_module(module_name)
	if module and module.has_method("get_api"):
		return module.get_api()
	return null

## Loads a preset configuration for a module taking [module_name] and [preset_name]
## [code]var success = module_manager.load_module_preset("double_jump", "speedrun")[/code]
func load_module_preset(module_name: String, preset_name: String) -> bool:
	var api = get_module_api(module_name)
	if api and api.has_method("load_preset"):
		return api.load_preset(preset_name)
	
	print("ModuleManager: Cannot load preset for module: ", module_name)
	return false

## Gets available presets for a module taking [module_name]
## [code]var presets = module_manager.get_module_presets("double_jump")[/code]
func get_module_presets(module_name: String) -> Array[String]:
	var api = get_module_api(module_name)
	if api and api.has_method("get_available_presets"):
		return api.get_available_presets()
	
	return []

## Saves a module's current configuration taking [module_name] and [file_path]
## [code]var success = module_manager.save_module_config("double_jump", "user://my_config.tres")[/code]
func save_module_config(module_name: String, file_path: String) -> bool:
	var api = get_module_api(module_name)
	if api and api.has_method("save_config"):
		return api.save_config(file_path)
	
	print("ModuleManager: Cannot save config for module: ", module_name)
	return false

## Resets a module's configuration to default values taking [module_name]
## [code]var success = module_manager.reset_module_to_defaults("double_jump")[/code]
func reset_module_to_defaults(module_name: String) -> bool:
	var api = get_module_api(module_name)
	if api and api.has_method("reset_to_defaults"):
		return api.reset_to_defaults()
	
	print("ModuleManager: Cannot reset config for module: ", module_name)
	return false

## Merges configuration settings into a module's current config taking [module_name] and [config]
## [code]var success = module_manager.merge_module_config("double_jump", partial_config)[/code]
func merge_module_config(module_name: String, config: ModuleConfig) -> bool:
	var api = get_module_api(module_name)
	if api and api.has_method("merge_config"):
		return api.merge_config(config)
	
	print("ModuleManager: Cannot merge config for module: ", module_name)
	return false 