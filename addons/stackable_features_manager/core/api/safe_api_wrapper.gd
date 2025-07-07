## Module: SafeAPIWrapper
## Purpose: Universal wrapper that handles both enabled and disabled modules gracefully
## Dependencies: ServiceLocator
##

# Universal safe wrapper that handles all API calls gracefully
# Works for both enabled modules (forwards to real API) and disabled modules (safe fallbacks)

@tool
class_name SafeAPIWrapper
extends Object

## The real module API (if enabled) or null (if disabled)
var _real_api: Variant

## The module name for error reporting
var _module_name: String

## Whether the module is currently enabled
var _is_enabled: bool

## Initialize the wrapper taking [module_name], [real_api], and [is_enabled] [br]
## [code]SafeAPIWrapper.new("jump_boost", api, true)[/code]
func _init(module_name: String, real_api: Variant = null, is_enabled: bool = false) -> void:
	_module_name = module_name
	_real_api = real_api
	_is_enabled = is_enabled

## Check if we need to refresh the API state (for cases where module loads after wrapper creation) [br]
## [code]_refresh_api_state()[/code]
func _refresh_api_state() -> void:
	# If we don't have a real API but the module might be loaded now, try to get it
	if not _real_api:
		var manager = ServiceLocator.get_instance().get_service("ModuleManager")
		if manager and manager.is_module_enabled(_module_name):
			var api = manager.get_module_api(_module_name)
			if api:
				_real_api = api
				_is_enabled = true

## Handle method calls with your preferred logic [br]
## [code]_handle_method_call(method, args)[/code]
func _handle_method_call(method: StringName, args: Array) -> Variant:
	# Always check if we can refresh our API state first
	_refresh_api_state()
	
	# Case 1: Module doesn't exist or is disabled
	# Don't even check if method exists, just handle gracefully
	if not _is_enabled or not _real_api:
		return _handle_disabled_module_call(method, args)
	
	# Case 2 & 3: Module exists and is active
	# Check if method exists in the real API
	if _real_api.has_method(method):
		# Method exists - run it on the real API
		return _real_api.callv(method, args)
	else:
		# Method doesn't exist - handle gracefully
		_log_warning("Method '" + str(method) + "()' does not exist in module '" + _module_name + "' - returning safe default")
		return _get_safe_default_for_method(method)

## Handle all method calls gracefully (legacy - kept for compatibility) [br]
## [code]_call(method, args)[/code]
func _call(method: StringName, args: Array) -> Variant:
	return _handle_method_call(method, args)

## Handle calls for disabled modules [br]
## [code]_handle_disabled_module_call(method, args)[/code]
func _handle_disabled_module_call(method: StringName, args: Array) -> Variant:
	# Handle common status methods
	if method == "get_boost_status":
		return {
			"active": false,
			"cooling_down": false,
			"current_uses": 0,
			"max_uses": 0,
			"boost_remaining": 0.0,
			"cooldown_remaining": 0.0,
			"module_status": "disabled",
			"module_name": _module_name
		}
	
	# Handle common getter methods (silent)
	elif method == "get_boost_multiplier":
		return 1.0
	elif method == "get_boost_duration":
		return 0.0
	elif method == "get_module_name":
		return _module_name
	elif method == "is_module_valid":
		return false
	elif method == "get_config":
		return null
	
	# Handle action methods (log warning)
	elif method == "activate_boost" or method == "deactivate_boost":
		_log_warning(str(method) + "() call ignored")
		return false
	
	# Handle setter methods (log warning)
	elif method == "set_boost_multiplier" or method == "set_boost_duration":
		_log_warning(str(method) + "(" + str(args[0] if args.size() > 0 else "") + ") call ignored")
		return
	elif method == "set_config" or method == "merge_config":
		_log_warning(str(method) + "() call ignored")
		return false
	
	# Handle unknown methods
	else:
		_log_warning("Unknown method '" + str(method) + "()' called - returning safe default")
		return _get_safe_default_for_method(method)

## Get safe default return value for unknown methods [br]
## [code]_get_safe_default_for_method(method)[/code]
func _get_safe_default_for_method(method: StringName) -> Variant:
	# Return appropriate defaults based on common method patterns
	var method_str = str(method)
	
	# Action methods (activate_, deactivate_, etc.) should return false
	if method_str.begins_with("activate_") or method_str.begins_with("deactivate_"):
		return false
	
	# Boolean methods (is_, has_, can_, etc.) should return false
	if method_str.begins_with("is_") or method_str.begins_with("has_") or method_str.begins_with("can_"):
		return false
	
	# Getter methods that might return numbers
	if method_str.begins_with("get_") and (method_str.ends_with("_multiplier") or method_str.ends_with("_duration") or method_str.ends_with("_count")):
		return 0.0
	
	# Status methods should return empty status
	if method_str.ends_with("_status"):
		return {
			"active": false,
			"module_status": "method_not_found",
			"module_name": _module_name
		}
	
	# Config methods should return false for setters, null for getters
	if method_str.begins_with("set_") or method_str.begins_with("merge_"):
		return false
	
	# For unknown methods that look like actions, return false
	# This covers cases like "activ_boost" which is likely an action
	return false

## Log warning messages [br]
## [code]_log_warning(message)[/code]
func _log_warning(message: String) -> void:
	var status = "disabled" if not _is_enabled else "enabled"
	push_warning("Module '" + _module_name + "' (" + status + ") - " + message)

## Get the module name [br]
## [code]get_module_name()[/code]
func get_module_name() -> String:
	return _module_name

## Check if module is valid [br]
## [code]is_module_valid()[/code]
func is_module_valid() -> bool:
	return _is_enabled and _real_api != null

# =============================================================================
# COMMON API METHODS - Implemented to handle method calls gracefully
# =============================================================================

## Get boost status [br]
## [code]get_boost_status()[/code]
func get_boost_status() -> Dictionary:
	return _handle_method_call("get_boost_status", [])

## Get boost multiplier [br]
## [code]get_boost_multiplier()[/code]
func get_boost_multiplier() -> float:
	return _handle_method_call("get_boost_multiplier", [])

## Get boost duration [br]
## [code]get_boost_duration()[/code]
func get_boost_duration() -> float:
	return _handle_method_call("get_boost_duration", [])

## Get module configuration [br]
## [code]get_config()[/code]
func get_config() -> Variant:
	return _handle_method_call("get_config", [])

## Activate boost [br]
## [code]activate_boost()[/code]
func activate_boost() -> bool:
	return _handle_method_call("activate_boost", [])

## Deactivate boost [br]
## [code]deactivate_boost()[/code]
func deactivate_boost() -> bool:
	return _handle_method_call("deactivate_boost", [])

## Set boost multiplier [br]
## [code]set_boost_multiplier(2.0)[/code]
func set_boost_multiplier(multiplier: float) -> void:
	_handle_method_call("set_boost_multiplier", [multiplier])

## Set boost duration [br]
## [code]set_boost_duration(1.0)[/code]
func set_boost_duration(duration: float) -> void:
	_handle_method_call("set_boost_duration", [duration])

## Set module configuration [br]
## [code]set_config(config)[/code]
func set_config(config: Variant) -> bool:
	return _handle_method_call("set_config", [config])

## Merge module configuration [br]
## [code]merge_config(config)[/code]
func merge_config(config: Variant) -> bool:
	return _handle_method_call("merge_config", [config])

# =============================================================================
# DYNAMIC METHOD HANDLING FOR UNKNOWN METHODS
# =============================================================================

## Handle the intentional typo for testing [br]
## [code]activ_boost()[/code]
func activ_boost() -> bool:
	return _handle_method_call("activ_boost", [])

 
