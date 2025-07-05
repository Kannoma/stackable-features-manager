## Module: NullSafeAPI
## Purpose: Null-safe proxy API that provides graceful fallbacks when modules are disabled
## Dependencies: ModuleAPI
##

# Null-safe proxy API that handles disabled modules gracefully
# Provides sensible defaults and silent operation for status calls
# Only logs warnings for actual action calls that should be noticed

@tool
class_name NullSafeAPI
extends ModuleAPI

## The module name this proxy represents
var _module_name: String

## Initialize the null-safe API proxy taking [module_name] [br]
## [code]NullSafeAPI.new("jump_boost")[/code]
func _init(module_name: String) -> void:
	super(null)  # Call parent constructor with null module
	_module_name = module_name
	_module = null  # No actual module - this is a proxy

## Tell Godot that we can handle any method call to prevent runtime errors [br]
## [code]_has_method(method_name)[/code]
func _has_method(method_name: StringName) -> bool:
	# Always return true so Godot routes all method calls to our _call() method
	return true

## Intercept any method calls that don't exist and handle them gracefully [br]
## [code]_call(method, args)[/code]
func _call(method: StringName, args: Array) -> Variant:
	# Handle common status methods
	if method == "get_boost_status":
		return _safe_status_call(str(method))
	
	# Handle common getter methods
	elif method == "get_boost_multiplier":
		return _safe_getter_call(str(method), 1.0)
	elif method == "get_boost_duration":
		return _safe_getter_call(str(method), 0.0)
	
	# Handle common action methods
	elif method == "activate_boost" or method == "deactivate_boost":
		return _safe_action_call(str(method))
	
	# Handle common setter methods
	elif method == "set_boost_multiplier" or method == "set_boost_duration":
		_safe_setter_call(str(method), args[0] if args.size() > 0 else null)
		return
	
	# Handle config methods
	elif method == "get_config":
		return null
	elif method == "set_config" or method == "merge_config":
		_log_action_warning(str(method) + "() call ignored")
		return false
	
	# Handle any other method calls
	else:
		_log_action_warning("Unknown method '" + str(method) + "()' called - returning null")
		return null

## Returns the name of the module this proxy represents [br]
## [code]var name = api.get_module_name()[/code]
func get_module_name() -> String:
	return _module_name

## Always returns false since this is a proxy for a disabled module [br]
## [code]if api.is_module_valid():[/code]
func is_module_valid() -> bool:
	return false

## Returns null silently (config access is often checked) [br]
## [code]var config = api.get_config()[/code]
func get_config() -> ModuleConfig:
	return null

## Returns false and logs a warning every time (config changes are actions) taking [config] [br]
## [code]var success = api.set_config(new_config)[/code]
func set_config(config: ModuleConfig) -> bool:
	_log_action_warning("set_config() call ignored")
	return false

## Returns false and logs a warning every time (config changes are actions) taking [config] [br]
## [code]var success = api.merge_config(partial_config)[/code]
func merge_config(config: ModuleConfig) -> bool:
	_log_action_warning("merge_config() call ignored")
	return false

## Log a warning every time an action is called on disabled module taking [message] [br]
## [code]_log_action_warning("method_name() call ignored")[/code]
func _log_action_warning(message: String) -> void:
	push_warning("Module '" + _module_name + "' is disabled - " + message)

# =============================================================================
# MODULE-SPECIFIC SAFE METHODS
# =============================================================================
# These methods provide safe defaults for common module operations
# They can be overridden by specific null-safe implementations

## Safe action call that returns false and logs a warning every time taking [method_name] [br]
## [code]var result = api._safe_action_call("activate_boost")[/code]
func _safe_action_call(method_name: String) -> bool:
	_log_action_warning(method_name + "() call ignored")
	return false

## Safe status call that returns informative status for disabled modules taking [method_name] [br]
## [code]var result = api._safe_status_call("get_boost_status")[/code]
func _safe_status_call(method_name: String) -> Dictionary:
	# Return informative status indicating module is disabled
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

## Safe getter call that returns default value silently taking [method_name] and [default_value] [br]
## [code]var result = api._safe_getter_call("get_boost_multiplier", 1.0)[/code]
func _safe_getter_call(method_name: String, default_value: Variant) -> Variant:
	# Getter calls are silent - they're expected to be called frequently
	return default_value

## Safe setter that logs a warning every time taking [method_name] and [value] [br]
## [code]api._safe_setter_call("set_boost_multiplier", 2.0)[/code]
func _safe_setter_call(method_name: String, value: Variant) -> void:
	_log_action_warning(method_name + "(" + str(value) + ") call ignored")

# =============================================================================
# COMMON API METHODS WITH SAFE DEFAULTS
# =============================================================================
# These provide the standard interface that all modules should have

## Returns false for disabled modules (logs warning every time) [br]
## [code]var success = api.activate_boost()[/code]
func activate_boost() -> bool:
	return _safe_action_call("activate_boost")

## Returns empty status for disabled modules (silent) [br]
## [code]var status = api.get_boost_status()[/code]
func get_boost_status() -> Dictionary:
	return _safe_status_call("get_boost_status")

## Returns false for disabled modules (logs warning every time) [br]
## [code]var success = api.deactivate_boost()[/code]
func deactivate_boost() -> bool:
	return _safe_action_call("deactivate_boost")

## Safe setter for disabled modules (logs warning every time) taking [multiplier] [br]
## [code]api.set_boost_multiplier(2.0)[/code]
func set_boost_multiplier(multiplier: float) -> void:
	_safe_setter_call("set_boost_multiplier", multiplier)

## Safe setter for disabled modules (logs warning every time) taking [duration] [br]
## [code]api.set_boost_duration(1.0)[/code]
func set_boost_duration(duration: float) -> void:
	_safe_setter_call("set_boost_duration", duration)

## Returns safe default for disabled modules (silent) [br]
## [code]var multiplier = api.get_boost_multiplier()[/code]
func get_boost_multiplier() -> float:
	return _safe_getter_call("get_boost_multiplier", 1.0) as float

## Returns safe default for disabled modules (silent) [br]
## [code]var duration = api.get_boost_duration()[/code]
func get_boost_duration() -> float:
	return _safe_getter_call("get_boost_duration", 0.0) as float

# =============================================================================
# EXTENSIBILITY
# =============================================================================
# Specific modules can create their own null-safe implementations by extending this class
# and overriding the specific methods they need with better defaults or behavior 
