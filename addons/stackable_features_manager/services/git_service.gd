## Consolidated Git service for all git operations and workflows [br]
## Handles git settings, repository operations, file management, and complex workflows
##
class_name GitService
extends RefCounted

## Workflow state enum
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

## Signals for git operations and workflows
signal git_operation_completed(success: bool, message: String)
signal git_settings_configured()
signal repository_cloned(success: bool, path: String)
signal workflow_completed(success: bool, message: String)
signal git_settings_needed(setting_type: String)
signal repository_url_needed(module_id: String)

## Git settings
var git_client_path: String = ""
var default_module_folder: String = ""

## Workflow state
var current_state: WorkflowState = WorkflowState.IDLE
var current_module_id: String = ""
var current_repository_url: String = ""
var current_dest_path: String = ""

## Service dependencies
var manifest_manager: ManifestManager
var module_manager: ModuleManager

## Initialize git service with module manager dependency [br]
## [code]var git_service = GitService.new(module_manager)[/code]
func _init(p_module_manager: ModuleManager = null) -> void:
	manifest_manager = ManifestManager.new()
	module_manager = p_module_manager
	load_git_settings()

# =============================================================================
# SETTINGS MANAGEMENT
# =============================================================================

## Load git settings from EditorInterface [br]
## [code]load_git_settings()[/code]
func load_git_settings() -> void:
	var editor_settings = EditorInterface.get_editor_settings()
	var git_client_setting = editor_settings.get_setting("stackable_features/git_client_path")
	var module_folder_setting = editor_settings.get_setting("stackable_features/default_module_folder")
	
	git_client_path = git_client_setting if git_client_setting != null else ""
	default_module_folder = module_folder_setting if module_folder_setting != null else ""

## Save git settings to EditorInterface [br]
## [code]save_git_settings()[/code]
func save_git_settings() -> void:
	var editor_settings = EditorInterface.get_editor_settings()
	editor_settings.set_setting("stackable_features/git_client_path", git_client_path)
	editor_settings.set_setting("stackable_features/default_module_folder", default_module_folder)

## Check if git settings are configured [br]
## [code]if git_service.are_git_settings_configured():[/code]
func are_git_settings_configured() -> bool:
	return git_client_path != "" and default_module_folder != "" and FileAccess.file_exists(git_client_path) and DirAccess.dir_exists_absolute(default_module_folder)

## Set git client path taking [path] [br]
## [code]git_service.set_git_client_path("C:/Program Files/Git/bin/git.exe")[/code]
func set_git_client_path(path: String) -> void:
	git_client_path = path
	save_git_settings()

## Set default module folder taking [path] [br]
## [code]git_service.set_default_module_folder("C:/Dev/Modules")[/code]
func set_default_module_folder(path: String) -> void:
	default_module_folder = path
	save_git_settings()

## Get git client path [br]
## [code]var path = git_service.get_git_client_path()[/code]
func get_git_client_path() -> String:
	return git_client_path

## Get default module folder [br]
## [code]var folder = git_service.get_default_module_folder()[/code]
func get_default_module_folder() -> String:
	return default_module_folder

# =============================================================================
# REPOSITORY OPERATIONS
# =============================================================================

## Initialize git repository in directory taking [path] [br]
## [code]var result = git_service.initialize_repository("C:/Dev/my_module")[/code]
func initialize_repository(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "init"], output, true, true)
	
	if exit_code != 0:
		var error_msg = "Git init failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)
	
	# Add all files and make initial commit
	var add_result = stage_all_files(path)
	if add_result.is_error():
		return add_result
	
	var commit_result = create_initial_commit(path)
	if commit_result.is_error():
		return commit_result
	
	return Result.success("Repository initialized successfully with initial commit")

## Clone repository to destination path taking [repository_url] and [dest_path] [br]
## [code]var result = git_service.clone_repository("https://github.com/user/repo.git", "C:/Dev/repo")[/code]
func clone_repository(repository_url: String, dest_path: String) -> Result:
	# Convert res:// path to absolute path if needed
	var absolute_dest_path = dest_path
	if dest_path.begins_with("res://"):
		absolute_dest_path = ProjectSettings.globalize_path(dest_path)
	
	var output = []
	var exit_code = OS.execute("git", ["clone", repository_url, absolute_dest_path], output, true, true)
	
	if exit_code == 0:
		repository_cloned.emit(true, dest_path)
		return Result.success("Repository cloned successfully to: " + dest_path)
	else:
		var error_msg = "Git clone failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		repository_cloned.emit(false, dest_path)
		return Result.failure(error_msg)

## Check if directory is a git repository taking [path] [br]
## [code]if git_service.is_git_repository("C:/Dev/my_module").is_ok():[/code]
func is_git_repository(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "rev-parse", "--git-dir"], output, true, true)
	
	if exit_code == 0:
		return Result.success("Directory is a git repository")
	else:
		return Result.failure("Directory is not a git repository")

## Stage all files in repository taking [path] [br]
## [code]var result = git_service.stage_all_files("C:/Dev/my_module")[/code]
func stage_all_files(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "add", "-A"], output, true, true)
	
	if exit_code == 0:
		return Result.success("Files staged successfully")
	else:
		var error_msg = "Git add failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)

## Create initial commit taking [path] [br]
## [code]var result = git_service.create_initial_commit("C:/Dev/my_module")[/code]
func create_initial_commit(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "commit", "-m", "Initial commit - Module copied from stackable features"], output, true, true)
	
	if exit_code == 0:
		return Result.success("Initial commit created successfully")
	else:
		var error_msg = "Git commit failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)

# =============================================================================
# FILE OPERATIONS
# =============================================================================

## Copy module files recursively from source to destination, preserving git history taking [source_path] and [dest_path] [br]
## [code]var result = git_service.copy_module_files("source/path", "dest/path")[/code]
func copy_module_files(source_path: String, dest_path: String) -> Result:
	var source_dir = DirAccess.open(source_path)
	if not source_dir:
		return Result.failure("Cannot open source directory: " + source_path)
	
	var dest_dir = DirAccess.open(dest_path)
	if not dest_dir:
		return Result.failure("Cannot open destination directory: " + dest_path)
	
	# Clear destination directory (except .git) to handle deletions
	_clear_directory_except_git(dest_dir, dest_path)
	
	return _copy_directory_recursive(source_dir, dest_dir, source_path, dest_path)

## Clear directory except .git folder [br]
## [code]_clear_directory_except_git(dest_dir, dest_path)[/code]
func _clear_directory_except_git(dest_dir: DirAccess, dest_path: String) -> void:
	dest_dir.list_dir_begin()
	var file_name = dest_dir.get_next()
	
	while file_name != "":
		if file_name != ".git":
			var full_path = dest_path + "/" + file_name
			if dest_dir.current_is_dir():
				# Remove directory recursively
				OS.move_to_trash(ProjectSettings.globalize_path(full_path))
			else:
				# Remove file
				dest_dir.remove(file_name)
		file_name = dest_dir.get_next()
	
	dest_dir.list_dir_end()

## Internal recursive directory copy [br]
## [code]_copy_directory_recursive(source_dir, dest_dir, source_path, dest_path)[/code]
func _copy_directory_recursive(source_dir: DirAccess, dest_dir: DirAccess, source_path: String, dest_path: String) -> Result:
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()
	
	while file_name != "":
		var source_file_path = source_path + "/" + file_name
		var dest_file_path = dest_path + "/" + file_name
		
		if source_dir.current_is_dir():
			# Skip .git directory to preserve git history
			if file_name == ".git":
				file_name = source_dir.get_next()
				continue
			
			# Create directory if it doesn't exist
			if not dest_dir.dir_exists(file_name):
				dest_dir.make_dir(file_name)
			
			# Recursively copy directory contents
			var recursive_result = copy_module_files(source_file_path, dest_file_path)
			if recursive_result.is_error():
				return recursive_result
		else:
			# Skip .uid files (Godot internal metadata)
			if file_name.ends_with(".uid"):
				file_name = source_dir.get_next()
				continue
			
			# Copy file
			var copy_result = source_dir.copy(source_file_path, dest_file_path)
			if copy_result != OK:
				return Result.failure("Failed to copy file: " + file_name)
		
		file_name = source_dir.get_next()
	
	source_dir.list_dir_end()
	return Result.success("Module files copied successfully")



## Sync module to repository, handling both new and existing destinations taking [source_path], [dest_path], and [repository_url] [br]
## [code]var result = git_service.sync_module_to_repository("stackable_features/jump_boost", "C:/Dev/jump_boost", "https://github.com/user/repo.git")[/code]
func sync_module_to_repository(source_path: String, dest_path: String, repository_url: String) -> Result:
	# Check if destination directory exists
	if DirAccess.dir_exists_absolute(dest_path):
		# Directory exists - copy files over, preserving git history
		print("Destination exists, copying files over: ", dest_path)
		
		# Check if it's a git repository
		var git_dir = dest_path + "/.git"
		if not DirAccess.dir_exists_absolute(git_dir):
			return Result.failure("Destination exists but is not a git repository: " + dest_path)
		
		# Copy module files from source to destination, preserving git history
		var copy_result = copy_module_files(source_path, dest_path)
		if copy_result.is_error():
			return copy_result
		
		print("Files copied successfully to existing repository")
		return Result.success("Module files synchronized with existing repository")
	else:
		# Directory doesn't exist - clone repository if URL provided
		if repository_url != "":
			var clone_result = clone_repository(repository_url, dest_path)
			if clone_result.is_error():
				return clone_result
			
			print("Repository cloned successfully to: ", dest_path)
			
			# Copy module files from source to the newly cloned destination
			var copy_result = copy_module_files(source_path, dest_path)
			if copy_result.is_error():
				return copy_result
			
			print("Module files copied to cloned repository")
			return Result.success("Repository cloned and module files synchronized successfully")
		else:
			# No repository URL - just initialize empty repository
			var init_result = initialize_repository(dest_path)
			if init_result.is_error():
				return init_result
			
			return Result.success("Repository initialized successfully")

# =============================================================================
# CLIENT INTEGRATION
# =============================================================================

## Open folder in configured git client taking [path] [br]
## [code]git_service.open_in_git_client("C:/Dev/jump_boost")[/code]
func open_in_git_client(path: String) -> bool:
	if git_client_path == "":
		print("No git client configured")
		return false
	
	if not FileAccess.file_exists(git_client_path):
		print("Git client not found: ", git_client_path)
		return false
	
	if not DirAccess.dir_exists_absolute(path):
		print("Module path not found: ", path)
		return false
	
	var git_client_name = git_client_path.get_file().get_basename().to_lower()
	var success = false
	
	print("Opening git client: ", git_client_path)
	print("With module path: ", path)
	
	# Handle different git clients
	if git_client_name.contains("git"):
		# For Git Bash or Git GUI - use --cd to set working directory
		success = OS.execute(git_client_path, ["--cd=" + path], [], false) == 0
		if not success:
			# Fallback: just pass the path
			success = OS.execute(git_client_path, [path], [], false) == 0
	elif git_client_name.contains("sourcetree"):
		# For SourceTree
		success = OS.execute(git_client_path, ["-f", path], [], false) == 0
	elif git_client_name.contains("gitkraken"):
		# For GitKraken
		success = OS.execute(git_client_path, ["-p", path], [], false) == 0
	elif git_client_name.contains("code"):
		# For VS Code
		success = OS.execute(git_client_path, [path], [], false) == 0
	else:
		# Generic approach - just open with the path
		success = OS.execute(git_client_path, [path], [], false) == 0
	
	if success:
		print("Git client opened successfully")
	else:
		print("Failed to open git client")
	
	return success

# =============================================================================
# WORKFLOW MANAGEMENT
# =============================================================================

## Start git integration workflow for module taking [module_id] [br]
## [code]git_service.start_git_integration("jump_boost")[/code]
func start_git_integration(module_id: String) -> void:
	reset_workflow_state()
	current_module_id = module_id
	current_state = WorkflowState.CHECKING_SETTINGS
	
	# Check if git settings are configured
	if not are_git_settings_configured():
		prompt_for_git_settings()
		return
	
	# Settings are configured, proceed with URL check
	check_repository_url()

## Continue workflow after git client is configured [br]
## [code]git_service.continue_after_git_client_configured()[/code]
func continue_after_git_client_configured() -> void:
	if current_state != WorkflowState.PROMPTING_GIT_CLIENT:
		return
	
	# Check if module folder is also configured
	if get_default_module_folder() == "" or not DirAccess.dir_exists_absolute(get_default_module_folder()):
		prompt_for_module_folder()
		return
	
	# Both settings configured, continue workflow
	check_repository_url()

## Continue workflow after module folder is configured [br]
## [code]git_service.continue_after_module_folder_configured()[/code]
func continue_after_module_folder_configured() -> void:
	if current_state != WorkflowState.PROMPTING_MODULE_FOLDER:
		return
	
	check_repository_url()

## Continue workflow with repository URL taking [repository_url] [br]
## [code]git_service.continue_with_repository_url("https://github.com/user/repo.git")[/code]
func continue_with_repository_url(repository_url: String) -> void:
	if current_state != WorkflowState.PROMPTING_REPOSITORY_URL:
		return
	
	current_repository_url = repository_url
	execute_git_integration()

## Execute the actual git integration [br]
## [code]execute_git_integration()[/code]
func execute_git_integration() -> void:
	current_state = WorkflowState.COPYING_MODULE
	
	if not module_manager:
		fail_workflow("Module manager not available")
		return
	
	# Get module information
	var available_modules = module_manager.get_available_modules()
	if not current_module_id in available_modules:
		fail_workflow("Module not found: " + current_module_id)
		return
	
	var module_info = available_modules[current_module_id]
	var config = module_info.config
	var source_path = module_info.path
	
	# Update the manifest with repository URL if needed
	if current_repository_url != config.get_repository():
		var manifest_result = update_manifest_repository(source_path, current_repository_url)
		if manifest_result.is_error():
			fail_workflow("Failed to update manifest: " + manifest_result.get_error())
			return
		
		# Refresh config to get updated repository URL
		config.set_repository(current_repository_url)
	
	# Create destination path
	current_dest_path = get_default_module_folder() + "/" + current_module_id
	
	# Sync module to repository - handles both new and existing destinations
	var sync_result = sync_module_to_repository(source_path, current_dest_path, current_repository_url)
	if sync_result.is_error():
		fail_workflow("Git operations failed: " + sync_result.get_error())
		return
	
	current_state = WorkflowState.OPENING_CLIENT
	
	# Open in git client so user can see the changes and commit when ready
	if not open_in_git_client(current_dest_path):
		fail_workflow("Failed to open git client")
		return
	
	complete_workflow("Git integration completed successfully. Module files copied and git client opened at: " + current_dest_path)

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
	if get_git_client_path() == "" or not FileAccess.file_exists(get_git_client_path()):
		current_state = WorkflowState.PROMPTING_GIT_CLIENT
		git_settings_needed.emit("git_client")
		return
	
	if get_default_module_folder() == "" or not DirAccess.dir_exists_absolute(get_default_module_folder()):
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
	if not module_manager:
		# Fallback: prompt for repository URL
		current_state = WorkflowState.PROMPTING_REPOSITORY_URL
		repository_url_needed.emit(current_module_id)
		return
	
	# Get module information
	var available_modules = module_manager.get_available_modules()
	if not current_module_id in available_modules:
		fail_workflow("Module not found: " + current_module_id)
		return
	
	var module_info = available_modules[current_module_id]
	var config = module_info.config
	
	# Check if repository URL already exists
	var repository_url = config.get_repository()
	if repository_url != "":
		# Repository URL exists, proceed with integration
		current_repository_url = repository_url
		execute_git_integration()
	else:
		# Repository URL needs to be prompted
		current_state = WorkflowState.PROMPTING_REPOSITORY_URL
		repository_url_needed.emit(current_module_id)

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
## [code]git_service.cancel_workflow()[/code]
func cancel_workflow() -> void:
	fail_workflow("Workflow canceled by user")

## Get current workflow state [br]
## [code]var state = git_service.get_current_state()[/code]
func get_current_state() -> WorkflowState:
	return current_state

## Check if workflow is active [br]
## [code]if git_service.is_workflow_active():[/code]
func is_workflow_active() -> bool:
	return current_state != WorkflowState.IDLE and current_state != WorkflowState.COMPLETED and current_state != WorkflowState.FAILED

## Update manifest file with repository URL taking [module_path] and [repository_url] [br]
## [code]var result = git_service.update_manifest_repository("path/to/module", "https://github.com/user/repo.git")[/code]
func update_manifest_repository(module_path: String, repository_url: String) -> Result:
	var manifest_path = module_path + "/manifest.json"
	return manifest_manager.update_repository_url(manifest_path, repository_url)

## Extract module name from repository URL taking [repository_url] [br]
## [code]var name = git_service.extract_module_name_from_url("https://github.com/user/my-awesome-module")[/code]
func extract_module_name_from_url(repository_url: String) -> String:
	var clean_url = repository_url
	if clean_url.ends_with(".git"):
		clean_url = clean_url.substr(0, clean_url.length() - 4)
	
	var parts = clean_url.split("/")
	if parts.size() >= 2:
		return parts[parts.size() - 1]
	
	return "" 