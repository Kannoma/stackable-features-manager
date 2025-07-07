## Module: {API_CLASS}
## Purpose: Lightweight API interface for the {MODULE_NAME} feature
## Dependencies: ModuleAPI
##

# Public API for {MODULE_NAME}
# External scripts interact with your module through this interface

@tool
class_name {API_CLASS}
extends ModuleAPI

# =============================================================================
# PUBLIC INTERFACE
# =============================================================================

## Example function for {MODULE_NAME} [br]
## [code]var success = {MODULE_ID}.example_function()[/code]
func example_function() -> bool:
	if _module and _module.has_method("example_function"):
		return _module.example_function()
	return false

## Returns current module status [br]
## [code]var status = {MODULE_ID}.get_status()[/code]
func get_status() -> Dictionary:
	if not _module:
		return {"active": false}
	return {"active": true, "module_name": "{MODULE_NAME}"}

# =============================================================================
# COMMON API PATTERNS
# =============================================================================

## Toggle module activation
# func activate() -> void:
# 	if _module and _module.has_method("activate"):
# 		_module.activate()

## Retrieve module data (most common pattern)
# func get_multiplier() -> float:
# 	if _module and _module.has_method("get_multiplier"):
# 		return _module.get_multiplier()
# 	return 1.0

## Execute module action
# func apply_to_player(player: Node) -> bool:
# 	if _module and _module.has_method("apply_to_player"):
# 		return _module.apply_to_player(player)
# 	return false

# =============================================================================
# INTEGRATION NOTES
# =============================================================================
# This file defines the public contract for your module.
# External scripts access your module via ModuleRegistry:
#
# var my_module = ModuleRegistry.get_module("{MODULE_ID}")
# if my_module:
#     my_module.activate()
#     var power = my_module.get_multiplier()

# =============================================================================
# USAGE EXAMPLE
# =============================================================================
# Player controller integration:
#
# var jump_boost = ModuleRegistry.get_module("jump_boost")
# if jump_boost and jump_boost.get_status().active:
#     velocity.y *= jump_boost.get_multiplier()

# =============================================================================
# CONFIGURATION ACCESS
# =============================================================================
# Module configuration is handled automatically:
#
# ModuleRegistry.load_preset("{MODULE_ID}", "speedrun")
# ModuleRegistry.get_config("{MODULE_ID}")
# ModuleRegistry.set_config("{MODULE_ID}", config)

# =============================================================================
# IMPLEMENTATION NOTES
# =============================================================================
# _module: Reference to your main module instance (automatically set)
# Always validate _module exists before calling methods to prevent null reference errors
# Return sensible defaults when module is unavailable 