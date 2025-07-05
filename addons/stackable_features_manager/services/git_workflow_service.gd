## Git workflow service for complex git integration workflows [br]
## Manages complex git workflows, state transitions, and coordination between services
##
class_name GitWorkflowService
extends RefCounted

## Workflow state
enum WorkflowState {
	IDLE,
	CHECKING_SETTINGS,
	PROMPTING_GIT_CLIENT,
	PROMPTING_MODULE_FOLDER,
	PROMPTING_REPOSITORY_URL,
	COPYING_MODULE,
	INITIALIZING_GIT,
	OPENING_CLIENT,
	COMPLETED,
	FAILED
}

## Current workflow context
var current_state: WorkflowState = WorkflowState.IDLE
var current_module_id: String = ""
var current_repository_url: String = ""
var current_dest_path: String = ""

## Service dependencies
var git_manager: GitManager
var module_operations: ModuleOperations

## Signals for workflow events
signal workflow_completed(success: bool, message: String)
signal git_settings_needed(setting_type: String)
signal repository_url_needed(module_id: String)

## Initialize workflow service with dependencies [br]
## [code]var workflow = GitWorkflowService.new(git_manager, module_operations)[/code]
func _init(p_git_manager: GitManager, p_module_operations: ModuleOperations) -> void:
	git_manager = p_git_manager
	module_operations = p_module_operations

## Start git integration workflow for module taking [module_id] [br]
## [code]workflow_service.start_git_integration("jump_boost")[/code]
func start_git_integration(module_id: String) -> void:
	reset_workflow_state()
	current_module_id = module_id
	current_state = WorkflowState.CHECKING_SETTINGS
	
	# Check if git settings are configured
	if not git_manager.are_git_settings_configured():
		prompt_for_git_settings()
		return
	
	# Settings are configured, proceed with URL check
	check_repository_url()

## Continue workflow after git client is configured [br]
## [code]workflow_service.continue_after_git_client_configured()[/code]
func continue_after_git_client_configured() -> void:
	if current_state != WorkflowState.PROMPTING_GIT_CLIENT:
		return
	
	# Check if module folder is also configured
	if git_manager.get_default_module_folder() == "" or not DirAccess.dir_exists_absolute(git_manager.get_default_module_folder()):
		prompt_for_module_folder()
		return
	
	# Both settings configured, continue workflow
	check_repository_url()

## Continue workflow after module folder is configured [br]
## [code]workflow_service.continue_after_module_folder_configured()[/code]
func continue_after_module_folder_configured() -> void:
	if current_state != WorkflowState.PROMPTING_MODULE_FOLDER:
		return
	
	check_repository_url()

## Continue workflow with repository URL taking [repository_url] [br]
## [code]workflow_service.continue_with_repository_url("https://github.com/user/repo.git")[/code]
func continue_with_repository_url(repository_url: String) -> void:
	if current_state != WorkflowState.PROMPTING_REPOSITORY_URL:
		return
	
	current_repository_url = repository_url
	execute_git_integration()

## Execute the actual git integration [br]
## [code]execute_git_integration()[/code]
func execute_git_integration() -> void:
	current_state = WorkflowState.COPYING_MODULE
	
	var result = module_operations.execute_git_integration_with_url(current_module_id, current_repository_url)
	
	if result.is_error():
		fail_workflow(result.get_error())
		return
	
	var data = result.get_data()
	current_dest_path = data.get("dest_path", "")
	
	complete_workflow("Git integration completed successfully")

## Reset workflow state [br]
## [code]reset_workflow_state()[/code]
func reset_workflow_state() -> void:
	current_state = WorkflowState.IDLE
	current_module_id = ""
	current_repository_url = ""
	current_dest_path = ""

## Prompt for git settings [br]
## [code]prompt_for_git_settings()[/code]
func prompt_for_git_settings() -> void:
	if git_manager.get_git_client_path() == "" or not FileAccess.file_exists(git_manager.get_git_client_path()):
		current_state = WorkflowState.PROMPTING_GIT_CLIENT
		git_settings_needed.emit("git_client")
		return
	
	if git_manager.get_default_module_folder() == "" or not DirAccess.dir_exists_absolute(git_manager.get_default_module_folder()):
		current_state = WorkflowState.PROMPTING_MODULE_FOLDER
		git_settings_needed.emit("module_folder")
		return

## Prompt for module folder [br]
## [code]prompt_for_module_folder()[/code]
func prompt_for_module_folder() -> void:
	current_state = WorkflowState.PROMPTING_MODULE_FOLDER
	git_settings_needed.emit("module_folder")

## Check repository URL and prompt if needed [br]
## [code]check_repository_url()[/code]
func check_repository_url() -> void:
	var result = module_operations.execute_git_integration_with_url_prompt(current_module_id)
	
	if result.is_error():
		fail_workflow(result.get_error())
		return
	
	var data = result.get_data()
	if data.get("needs_url_prompt", false):
		current_state = WorkflowState.PROMPTING_REPOSITORY_URL
		repository_url_needed.emit(current_module_id)
	else:
		# Repository URL already exists, continue
		var config = data.get("config")
		if config:
			current_repository_url = config.get_repository()
		execute_git_integration()

## Complete workflow successfully taking [message] [br]
## [code]complete_workflow("Success message")[/code]
func complete_workflow(message: String) -> void:
	current_state = WorkflowState.COMPLETED
	workflow_completed.emit(true, message)

## Fail workflow with error taking [error_message] [br]
## [code]fail_workflow("Error message")[/code]
func fail_workflow(error_message: String) -> void:
	current_state = WorkflowState.FAILED
	workflow_completed.emit(false, error_message)

## Cancel current workflow [br]
## [code]workflow_service.cancel_workflow()[/code]
func cancel_workflow() -> void:
	reset_workflow_state()
	workflow_completed.emit(false, "Workflow canceled by user")

## Get current workflow state [br]
## [code]var state = workflow_service.get_current_state()[/code]
func get_current_state() -> WorkflowState:
	return current_state

## Check if workflow is active [br]
## [code]if workflow_service.is_workflow_active():[/code]
func is_workflow_active() -> bool:
	return current_state != WorkflowState.IDLE and current_state != WorkflowState.COMPLETED and current_state != WorkflowState.FAILED

## Get current module ID [br]
## [code]var module_id = workflow_service.get_current_module_id()[/code]
func get_current_module_id() -> String:
	return current_module_id

## Get current destination path [br]
## [code]var path = workflow_service.get_current_dest_path()[/code]
func get_current_dest_path() -> String:
	return current_dest_path 