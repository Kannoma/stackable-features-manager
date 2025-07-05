## Module: ModuleConfig
## Purpose: Base class for all module-specific configuration resources
## Dependencies: None
##

# Base class for module configuration resources
# Provides common functionality for validation, merging, and serialization

@tool
class_name ModuleConfig
extends Resource

## Validates the configuration settings [br]
## [code]if config.is_valid():[/code]
func is_valid() -> bool:
	# Override in derived classes for specific validation
	return true

## Returns a default configuration instance [br]
## [code]var default = config.get_default_config()[/code]
func get_default_config() -> ModuleConfig:
	# Override in derived classes to return proper defaults
	return ModuleConfig.new()

## Merges another configuration into this one taking [other_config] [br]
## [code]config.merge_config(other_config)[/code]
func merge_config(other_config: ModuleConfig) -> void:
	# Override in derived classes for specific merge logic
	pass



## Creates a deep copy of this configuration [br]
## [code]var copy = config.clone()[/code]
func clone() -> ModuleConfig:
	# Default implementation uses resource duplication
	return duplicate(true)

## Returns the name of this configuration type [br]
## [code]var name = config.get_config_name()[/code]
func get_config_name() -> String:
	# Override in derived classes to provide specific name
	return "ModuleConfig" 