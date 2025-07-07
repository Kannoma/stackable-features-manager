## Module: FeatureConfig
## Purpose: Resource class for storing feature module metadata and configuration with git integration
## Dependencies: ModuleConfig
##

# Resource class for feature module metadata
# Supports both typed ModuleConfig and legacy Dictionary configuration with git integration

@tool
class_name FeatureConfig
extends Resource

## Feature metadata
@export var id: String = ""
@export var name: String = ""
@export var version: String = "1.0.0"
@export var description: String = ""
@export var author: String = ""
@export var entry_point: String = ""
@export var requires: Array[String] = []
@export var engine_versions: Array[String] = ["4.3", "4.4"]

## Git integration
@export var repository: String = ""

## Configuration data (typed ModuleConfig)
@export var module_config: ModuleConfig

## Checks if the feature configuration is valid [br]
## [code]if feature_config.is_valid():[/code]
func is_valid() -> bool:
	var basic_valid = id != "" and name != "" and entry_point != ""
	var config_valid = module_config == null or module_config.is_valid()
	return basic_valid and config_valid

## Returns the full path to the entry script taking [module_folder] [br]
## [code]config.get_entry_script_path("stackable_features/my_module")[/code]
func get_entry_script_path(module_folder: String) -> String:
	return module_folder + "/" + entry_point

## Returns the typed module configuration [br]
## [code]var config = feature_config.get_config()[/code]
func get_config() -> ModuleConfig:
	return module_config

## Sets the typed module configuration taking [config] [br]
## [code]feature_config.set_config(example_config)[/code]
func set_config(config: ModuleConfig) -> void:
	module_config = config

## Returns the repository URL for git integration [br]
## [code]var repo_url = feature_config.get_repository()[/code]
func get_repository() -> String:
	return repository

## Sets the repository URL for git integration taking [repo_url] [br]
## [code]feature_config.set_repository("https://github.com/user/repo.git")[/code]
func set_repository(repo_url: String) -> void:
	repository = repo_url

## Module configuration base class providing common functionality [br]
## Handles configuration loading, saving, and validation for stackable modules
##

## Module-aware resource loading that fixes script paths dynamically [br]
## [code]var config = FeatureConfig.load_module_resource("res://stackable_features/jump_boost/presets/speedrun.tres", "res://stackable_features/jump_boost/config.gd")[/code]
static func load_module_resource(resource_path: String, script_path: String) -> Resource:
	var resource = load(resource_path)
	if resource and script_path != "":
		# Get the script class and assign it
		var script = load(script_path)
		if script:
			resource.set_script(script)
	return resource

## Loads a preset from the module's presets directory taking [module_path] and [preset_name] [br]
## [code]var config = FeatureConfig.load_module_preset("res://stackable_features/jump_boost", "speedrun")[/code]
static func load_module_preset(module_path: String, preset_name: String) -> Resource:
	var preset_path = module_path + "/presets/" + preset_name + ".tres"
	var config_script_path = module_path + "/config.gd"
	
	# Check if files exist
	if not FileAccess.file_exists(preset_path):
		push_error("FeatureConfig: Preset file not found: " + preset_path)
		return null
	
	if not FileAccess.file_exists(config_script_path):
		push_error("FeatureConfig: Config script not found: " + config_script_path)
		return null
	
	return load_module_resource(preset_path, config_script_path)

## Loads a preset from any location (internal or external) taking [preset_path_or_name] and [module_name] [br]
## [code]var config = FeatureConfig.load_any_preset("speedrun", "jump_boost")[/code] for internal [br]
## [code]var config = FeatureConfig.load_any_preset("res://my_custom.tres", "jump_boost")[/code] for external
static func load_any_preset(preset_path_or_name: String, module_name: String) -> Resource:
	# If it contains "/" or ends with ".tres", treat as external file path
	if preset_path_or_name.contains("/") or preset_path_or_name.ends_with(".tres"):
		# External preset loading
		if not FileAccess.file_exists(preset_path_or_name):
			push_error("FeatureConfig: External preset file not found: " + preset_path_or_name)
			return null
		
		# Get the module path to find the config script
		var module_path = "res://stackable_features/" + module_name
		var config_script_path = module_path + "/config.gd"
		
		# Check if module config script exists
		if not FileAccess.file_exists(config_script_path):
			push_error("FeatureConfig: Module config script not found: " + config_script_path)
			return null
		
		# Load the external preset and assign the module's script
		return load_module_resource(preset_path_or_name, config_script_path)
	else:
		# Internal preset loading
		return load_module_preset("res://stackable_features/" + module_name, preset_path_or_name)

## Gets available presets for a module taking [module_path] [br]
## [code]var presets = FeatureConfig.get_module_presets("res://stackable_features/jump_boost")[/code]
static func get_module_presets(module_path: String) -> Array[String]:
	var presets: Array[String] = []
	var presets_dir = module_path + "/presets"
	
	if not DirAccess.dir_exists_absolute(presets_dir):
		return presets
	
	var dir = DirAccess.open(presets_dir)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tres"):
				presets.append(file_name.get_basename())
			file_name = dir.get_next()
		dir.list_dir_end()
	
	return presets 