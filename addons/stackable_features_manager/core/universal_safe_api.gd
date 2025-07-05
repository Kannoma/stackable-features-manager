## Module: UniversalSafeAPI
## Purpose: Bulletproof API that handles any method call without crashing
## Dependencies: None
##

# Universal safe API that intercepts ALL method calls
# This is the ultimate fallback when everything else fails

@tool
class_name UniversalSafeAPI
extends RefCounted

## The module name this represents
var module_name: String = "unknown"

## Initialize with module name [br]
## [code]UniversalSafeAPI.new("jump_boost")[/code]
func _init(name: String = "unknown") -> void:
	module_name = name

## Handle any method call that doesn't exist [br]
## [code]_call(method, args)[/code]
func _call(method: StringName, args: Array) -> Variant:
	# Handle status methods - return safe defaults
	if method == "get_boost_status":
		return {
			"active": false,
			"cooling_down": false,
			"current_uses": 0,
			"max_uses": 0,
			"boost_remaining": 0.0,
			"cooldown_remaining": 0.0,
			"module_status": "unavailable",
			"module_name": module_name
		}
	
	# Handle getter methods - return safe defaults
	elif method == "get_boost_multiplier":
		return 1.0
	elif method == "get_boost_duration":
		return 0.0
	elif method == "get_module_name":
		return module_name
	elif method == "is_module_valid":
		return false
	elif method == "get_config":
		return null
	
	# Handle action methods - return false (no-op)
	elif method == "activate_boost" or method == "deactivate_boost":
		return false
	
	# Handle setter methods - no-op
	elif method == "set_boost_multiplier" or method == "set_boost_duration":
		return
	elif method == "set_config" or method == "merge_config":
		return false
	
	# Handle any unknown method
	else:
		return null

## Override property access to prevent errors [br]
## [code]_get(property)[/code]
func _get(property: StringName) -> Variant:
	return null

## Override property setting to prevent errors [br]
## [code]_set(property, value)[/code]
func _set(property: StringName, value: Variant) -> bool:
	return true  # Indicate we handled it 