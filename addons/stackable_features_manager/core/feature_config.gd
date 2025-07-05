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