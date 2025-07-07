## Module: {CONFIG_CLASS}
## Purpose: Configuration resource for the {MODULE_NAME} feature
## Dependencies: ModuleConfig
##

# Configuration schema for {MODULE_NAME}

@tool
class_name {CONFIG_CLASS}
extends ModuleConfig

@export_group("Basic Settings")
@export var enabled: bool = true

# =============================================================================
# CONFIGURATION PROPERTIES
# =============================================================================

## Numeric range controls
# @export_range(0.1, 10.0, 0.1) var multiplier: float = 2.0
# @export_range(1, 100) var max_uses: int = 10

## String inputs
# @export var custom_message: String = "Boost activated!"

## Enumerated choices
# enum BoostType { TEMPORARY, PERMANENT }
# @export var boost_type: BoostType = BoostType.TEMPORARY

## Advanced configuration
# @export_group("Advanced")
# @export var debug_mode: bool = false

# =============================================================================
# VALIDATION LOGIC
# =============================================================================

## Validates configuration integrity
func is_valid() -> bool:
	return enabled != null

## Creates default configuration instance
func get_default_config() -> ModuleConfig:
	var config = {CONFIG_CLASS}.new()
	config.enabled = true
	return config

## Merges configuration from preset or external source
func merge_config(other_config: ModuleConfig) -> void:
	if other_config is {CONFIG_CLASS}:
		var other = other_config as {CONFIG_CLASS}
		enabled = other.enabled

## Returns configuration class identifier
func get_config_name() -> String:
	return "{CONFIG_CLASS}"

# =============================================================================
# VALIDATION EXAMPLES
# =============================================================================
# Implement validation logic in is_valid():
#
# if multiplier <= 0.0:
#     return false
# if max_uses < 1:
#     return false

# =============================================================================
# DEFAULT CONFIGURATION
# =============================================================================
# Set appropriate defaults in get_default_config():
#
# config.multiplier = 2.0
# config.max_uses = 10
# config.custom_message = "Default message"

# =============================================================================
# PRESET INTEGRATION
# =============================================================================
# Copy all exported properties in merge_config():
#
# multiplier = other.multiplier
# max_uses = other.max_uses
# custom_message = other.custom_message

# =============================================================================
# PRESET SYSTEM
# =============================================================================
# Presets are .tres resource files containing pre-configured settings.
# Common preset examples: speedrun.tres, casual.tres, debug.tres
#
# Creating presets:
# 1. Configure settings in Godot inspector
# 2. Right-click resource -> Save As
# 3. Save to module's /presets/ directory
#
# Loading presets:
# ModuleRegistry.load_preset("module_id", "preset_name") 