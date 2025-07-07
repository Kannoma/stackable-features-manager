## Result pattern for consistent error handling across services [br]
## Provides success/failure states with typed data and error messages
##
class_name Result
extends RefCounted

## Result state
var is_success: bool
var data: Variant
var error_message: String

## Create successful result with data taking [value] [br]
## [code]Result.success("operation completed")[/code]
static func success(value: Variant = null) -> Result:
	var result = Result.new()
	result.is_success = true
	result.data = value
	result.error_message = ""
	return result

## Create failed result with error message taking [message] [br]
## [code]Result.failure("Operation failed: invalid input")[/code]
static func failure(message: String) -> Result:
	var result = Result.new()
	result.is_success = false
	result.data = null
	result.error_message = message
	return result

## Check if result is successful [br]
## [code]if result.is_ok():[/code]
func is_ok() -> bool:
	return is_success

## Check if result is failure [br]
## [code]if result.is_error():[/code]
func is_error() -> bool:
	return not is_success

## Get data if successful, otherwise return default taking [default_value] [br]
## [code]var value = result.get_or("default")[/code]
func get_or(default_value: Variant) -> Variant:
	return data if is_success else default_value

## Get data if successful, otherwise return null [br]
## [code]var value = result.get_data()[/code]
func get_data() -> Variant:
	return data if is_success else null

## Get error message if failed, otherwise return empty string [br]
## [code]var error = result.get_error()[/code]
func get_error() -> String:
	return error_message if not is_success else "" 