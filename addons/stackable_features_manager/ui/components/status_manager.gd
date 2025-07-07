## Status manager for handling user feedback and status updates [br]
## Centralizes all status message handling with consistent formatting and timing
##
class_name StatusManager
extends RefCounted

## Reference to the status label
var status_label: Label

## Initialize status manager with label reference taking [label] [br]
## [code]var status_mgr = StatusManager.new(status_label)[/code]
func _init(label: Label) -> void:
	status_label = label

## Set status to ready state [br]
## [code]status_manager.set_ready()[/code]
func set_ready() -> void:
	status_label.text = "Ready"

## Set refreshing modules status [br]
## [code]status_manager.set_refreshing()[/code]
func set_refreshing() -> void:
	status_label.text = "Refreshing modules..."

## Set modules refreshed status [br]
## [code]status_manager.set_refreshed()[/code]
func set_refreshed() -> void:
	status_label.text = "Modules refreshed"

## Set module enabling status taking [module_name] [br]
## [code]status_manager.set_module_enabling("Jump Boost")[/code]
func set_module_enabling(module_name: String) -> void:
	status_label.text = "Enabling module: " + module_name

## Set module disabling status taking [module_name] [br]
## [code]status_manager.set_module_disabling("Jump Boost")[/code]
func set_module_disabling(module_name: String) -> void:
	status_label.text = "Disabling module: " + module_name

## Set module enabled success status taking [module_name] [br]
## [code]status_manager.set_module_enabled_success("Jump Boost")[/code]
func set_module_enabled_success(module_name: String) -> void:
	status_label.text = "Module enabled successfully: " + module_name

## Set module disabled success status taking [module_name] [br]
## [code]status_manager.set_module_disabled_success("Jump Boost")[/code]
func set_module_disabled_success(module_name: String) -> void:
	status_label.text = "Module disabled successfully: " + module_name

## Set module enable failure status taking [module_name] [br]
## [code]status_manager.set_module_enable_failed("Jump Boost")[/code]
func set_module_enable_failed(module_name: String) -> void:
	status_label.text = "Failed to enable module: " + module_name

## Set module disable failure status taking [module_name] [br]
## [code]status_manager.set_module_disable_failed("Jump Boost")[/code]
func set_module_disable_failed(module_name: String) -> void:
	status_label.text = "Failed to disable module: " + module_name

## Set git integration starting status taking [module_id] [br]
## [code]status_manager.set_git_integration_starting("jump_boost")[/code]
func set_git_integration_starting(module_id: String) -> void:
	status_label.text = "Starting git integration for " + module_id + "..."

## Set git client configured status taking [path] [br]
## [code]status_manager.set_git_client_configured("C:/Program Files/Git/bin/git.exe")[/code]
func set_git_client_configured(path: String) -> void:
	status_label.text = "Git client configured: " + path.get_file()

## Set module folder configured status taking [path] [br]
## [code]status_manager.set_module_folder_configured("C:/Dev/Modules")[/code]
func set_module_folder_configured(path: String) -> void:
	status_label.text = "Module folder configured: " + path.get_file()

## Set git client selection canceled status [br]
## [code]status_manager.set_git_client_canceled()[/code]
func set_git_client_canceled() -> void:
	status_label.text = "Git client selection canceled"

## Set module folder selection canceled status [br]
## [code]status_manager.set_module_folder_canceled()[/code]
func set_module_folder_canceled() -> void:
	status_label.text = "Module folder selection canceled"

## Set git integration setup status [br]
## [code]status_manager.set_git_integration_setup()[/code]
func set_git_integration_setup() -> void:
	status_label.text = "Setting up git integration..."

## Set git integration canceled status [br]
## [code]status_manager.set_git_integration_canceled()[/code]
func set_git_integration_canceled() -> void:
	status_label.text = "Git integration canceled - repository URL not provided"

## Set import canceled status [br]
## [code]status_manager.set_import_canceled()[/code]
func set_import_canceled() -> void:
	status_label.text = "Import canceled"

## Set importing module status [br]
## [code]status_manager.set_importing_module()[/code]
func set_importing_module() -> void:
	status_label.text = "Importing module..."

## Set git settings configured status [br]
## [code]status_manager.set_git_settings_configured()[/code]
func set_git_settings_configured() -> void:
	status_label.text = "Git settings configured successfully"

## Set repository cloned status taking [success] and [path] [br]
## [code]status_manager.set_repository_cloned(true, "path")[/code]
func set_repository_cloned(success: bool, path: String) -> void:
	if success:
		status_label.text = "Repository cloned successfully"
	else:
		status_label.text = "Failed to clone repository"

## Set module imported status taking [success] and [module_id] [br]
## [code]status_manager.set_module_imported(true, "jump_boost")[/code]
func set_module_imported(success: bool, module_id: String) -> void:
	if success:
		status_label.text = "Module imported successfully: " + module_id
	else:
		status_label.text = "Failed to import module"

## Set module copied status taking [success], [source_path] and [dest_path] [br]
## [code]status_manager.set_module_copied(true, "source", "dest")[/code]
func set_module_copied(success: bool, source_path: String, dest_path: String) -> void:
	if success:
		status_label.text = "Module copied successfully to: " + dest_path.get_file()
	else:
		status_label.text = "Failed to copy module"

## Set workflow completed status taking [success] and [message] [br]
## [code]status_manager.set_workflow_completed(true, "Success message")[/code]
func set_workflow_completed(success: bool, message: String) -> void:
	status_label.text = message

## Set git settings needed status taking [setting_type] [br]
## [code]status_manager.set_git_settings_needed("git_client")[/code]
func set_git_settings_needed(setting_type: String) -> void:
	if setting_type == "git_client":
		status_label.text = "Please select your Git client executable..."
	elif setting_type == "module_folder":
		status_label.text = "Please select default module folder..."

## Set repository URL needed status taking [module_id] [br]
## [code]status_manager.set_repository_url_needed("jump_boost")[/code]
func set_repository_url_needed(module_id: String) -> void:
	status_label.text = "Repository URL needed for module: " + module_id

## Set error status taking [error_message] [br]
## [code]status_manager.set_error("Invalid repository URL")[/code]
func set_error(error_message: String) -> void:
	status_label.text = error_message

## Set custom status taking [message] [br]
## [code]status_manager.set_status("Custom message")[/code]
func set_status(message: String) -> void:
	status_label.text = message

## Set git client opened status taking [path] [br]
## [code]status_manager.set_git_client_opened("C:/Dev/jump_boost")[/code]
func set_git_client_opened(path: String) -> void:
	status_label.text = "Opened " + path.get_file() + " in git client"

## Set git client open failed status [br]
## [code]status_manager.set_git_client_open_failed()[/code]
func set_git_client_open_failed() -> void:
	status_label.text = "Failed to open git client" 