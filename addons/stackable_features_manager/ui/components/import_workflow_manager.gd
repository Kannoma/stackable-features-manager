## Import workflow manager for handling module import operations [br]
## Manages the complete import workflow with validation and status feedback
##
class_name ImportWorkflowManager
extends RefCounted

## Signals for import workflow events
signal import_started()
signal import_completed(success: bool, message: String)
signal validation_failed(error_message: String)

## Service dependencies
var module_operations: ModuleOperations
var status_manager: StatusManager

## Initialize import workflow manager taking [p_module_operations] and [p_status_manager] [br]
## [code]var import_mgr = ImportWorkflowManager.new(module_operations, status_manager)[/code]
func _init(p_module_operations: ModuleOperations, p_status_manager: StatusManager) -> void:
	module_operations = p_module_operations
	status_manager = p_status_manager

## Start import workflow with repository URL taking [repository_url] [br]
## [code]await import_manager.start_import("https://github.com/user/repo")[/code]
func start_import(repository_url: String) -> void:
	# Validate the repository URL first
	var validation_result = module_operations.validate_import_url(repository_url)
	if validation_result.is_error():
		status_manager.set_error(validation_result.get_error())
		validation_failed.emit(validation_result.get_error())
		return
	
	# Start the import process
	import_started.emit()
	status_manager.set_importing_module()
	await import_module_from_repository(repository_url)

## Import a module from GitHub repository taking [repository_url] [br]
## [code]await import_manager.import_module_from_repository("https://github.com/Kannoma/stackable-jump-boost")[/code]
func import_module_from_repository(repository_url: String) -> void:
	var result = await module_operations.import_module_from_github(repository_url)
	
	if result.is_ok():
		var message = result.get_data()
		status_manager.set_status(message)
		import_completed.emit(true, message)
	else:
		var error = result.get_error()
		status_manager.set_error(error)
		import_completed.emit(false, error)

## Validate repository URL taking [repository_url] [br]
## [code]var is_valid = import_manager.validate_repository_url("https://github.com/user/repo")[/code]
func validate_repository_url(repository_url: String) -> bool:
	var validation_result = module_operations.validate_import_url(repository_url)
	return validation_result.is_ok()

## Get validation error for repository URL taking [repository_url] [br]
## [code]var error = import_manager.get_validation_error("invalid-url")[/code]
func get_validation_error(repository_url: String) -> String:
	var validation_result = module_operations.validate_import_url(repository_url)
	if validation_result.is_error():
		return validation_result.get_error()
	return "" 