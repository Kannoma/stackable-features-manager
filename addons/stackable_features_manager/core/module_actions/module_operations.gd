## Module operations service for handling module-related operations [br]
## Handles module importing, copying, and git integration workflows
##
class_name ModuleOperations
extends RefCounted

## Signals for module operations
signal module_operation_completed(success: bool, message: String)
signal module_imported(module_id: String, success: bool)
signal module_copied(source_path: String, dest_path: String, success: bool)

## Service dependencies
var module_manager: ModuleManager
var git_service: GitService
var http_request: HTTPRequest
var module_service: ModuleService
var http_service: HttpService
var manifest_manager: ManifestManager

## Initialize module operations with dependencies [br]
## [code]var operations = ModuleOperations.new(module_manager, git_service, http_request)[/code]
func _init(p_module_manager: ModuleManager, p_git_service: GitService, http_request_node: HTTPRequest) -> void:
	module_manager = p_module_manager
	git_service = p_git_service
	http_request = http_request_node
	module_service = ModuleService.new()
	http_service = HttpService.new(http_request_node)
	manifest_manager = ManifestManager.new()

## Copy module to destination path taking [source_path] and [dest_path] [br]
## [code]var result = module_ops.copy_module_to_destination("stackable_features/jump_boost", "C:/Dev/jump_boost")[/code]
func copy_module_to_destination(source_path: String, dest_path: String) -> Result:
	var copy_result = module_service.copy_module(source_path, dest_path)
	
	# Emit signal for backward compatibility
	module_copied.emit(source_path, dest_path, copy_result.is_ok())
	
	return copy_result

## Execute git integration with repository URL prompt first taking [module_id] [br]
## [code]var result = module_ops.execute_git_integration_with_url_prompt("jump_boost")[/code]
func execute_git_integration_with_url_prompt(module_id: String) -> Result:
	# Get module information
	var available_modules = module_manager.get_available_modules()
	if not module_id in available_modules:
		return Result.failure("Module not found: " + module_id)
	
	var module_info = available_modules[module_id]
	var config = module_info.config
	
	# Check if repository URL is already set
	var repository_url = config.get_repository()
	if repository_url != "":
		# Repository URL already exists, proceed with normal flow
		return execute_git_integration_with_url(module_id, repository_url)
	
	# Repository URL needs to be prompted - return special result
	return Result.success({
		"needs_url_prompt": true,
		"module_id": module_id,
		"config": config
	})

## Execute git integration with provided repository URL taking [module_id] and [repository_url] [br]
## [code]var result = module_ops.execute_git_integration_with_url("jump_boost", "https://github.com/user/repo.git")[/code]
func execute_git_integration_with_url(module_id: String, repository_url: String) -> Result:
	# Get module information
	var available_modules = module_manager.get_available_modules()
	if not module_id in available_modules:
		return Result.failure("Module not found: " + module_id)

	var module_info = available_modules[module_id]
	var config = module_info.config
	var source_path = module_info.path

	# First, update the manifest with repository URL
	var manifest_result = update_module_manifest_repository(module_id, repository_url)
	if manifest_result.is_error():
		return Result.failure("Failed to update manifest: " + manifest_result.get_error())

	# Refresh config to get updated repository URL
	config.set_repository(repository_url)

	# Create destination path
	var dest_path = git_service.get_default_module_folder() + "/" + module_id

	# Sync module to repository - handles both new and existing destinations
	var sync_result = git_service.sync_module_to_repository(source_path, dest_path, repository_url)
	if sync_result.is_error():
		return Result.failure("Git operations failed: " + sync_result.get_error())

	# Open in git client so user can see the changes and commit when ready
	if not git_service.open_in_git_client(dest_path):
		return Result.failure("Failed to open git client")

	return Result.success({
		"message": "Git integration completed successfully. Module files copied to cloned repository.",
		"dest_path": dest_path
	})

## Handle git operations for copied module taking [config], [source_path], and [dest_path] [br]
## [code]var result = handle_git_operations(config, "stackable_features/jump_boost", "C:/Dev/jump_boost")[/code]
func handle_git_operations(config: FeatureConfig, source_path: String, dest_path: String) -> Result:
	var repository_url = config.get_repository()
	
	# Sync module to repository - handles both new and existing destinations
	var sync_result = git_service.sync_module_to_repository(source_path, dest_path, repository_url)
	if sync_result.is_error():
		return sync_result
	
	# Open in git client
	if not git_service.open_in_git_client(dest_path):
		return Result.failure("Failed to open git client")
	
	return Result.success("Git operations completed successfully")

## Import a module from GitHub repository taking [repository_url] [br]
## [code]var result = await module_ops.import_module_from_github("https://github.com/Kannoma/stackable-jump-boost")[/code]
func import_module_from_github(repository_url: String) -> Result:
	# Step 1: Fetch and validate manifest
	var manifest_result = await http_service.fetch_manifest_from_github(repository_url)
	if manifest_result.is_error():
		return Result.failure("Invalid repository: " + manifest_result.get_error())
	
	var manifest_data = manifest_result.get_data()
	
	# Step 2: Validate manifest structure
	var validation_result = manifest_manager.validate_manifest(manifest_data)
	if validation_result.is_error():
		return Result.failure("Invalid manifest: " + validation_result.get_error())
	
	# Step 3: Check if module ID is unique
	var module_id = manifest_manager.extract_module_id(manifest_data)
	module_manager.refresh_available_modules()
	var available_modules = module_manager.get_available_modules()
	if module_id in available_modules:
		return Result.failure("Module with ID '" + module_id + "' already exists")
	
	# Step 4: Ensure stackable_features directory exists
	var stackable_features_path = "res://stackable_features"
	if not DirAccess.dir_exists_absolute(stackable_features_path):
		var dir = DirAccess.open("res://")
		if dir.make_dir("stackable_features") != OK:
			return Result.failure("Failed to create stackable_features directory")
	
	# Step 5: Clone the repository using module ID from manifest
	var dest_path = stackable_features_path + "/" + module_id
	
	var clone_result = git_service.clone_repository(repository_url, dest_path)
	if clone_result.is_error():
		module_imported.emit(module_id, false)
		return Result.failure("Failed to clone repository: " + clone_result.get_error())
	
	# Step 6: Refresh module manager and emit success
	module_manager.refresh_available_modules()
	module_imported.emit(module_id, true)
	
	return Result.success("Module '" + module_id + "' imported successfully")

## Validate import repository URL taking [repository_url] [br]
## [code]var result = module_ops.validate_import_url("https://github.com/user/repo")[/code]
func validate_import_url(repository_url: String) -> Result:
	if repository_url.strip_edges() == "":
		return Result.failure("Repository URL cannot be empty")
	
	if not http_service.validate_github_url(repository_url):
		return Result.failure("Invalid GitHub repository URL format")
	
	return Result.success("Repository URL is valid")

## Get module info for git integration taking [module_id] [br]
## [code]var info = module_ops.get_module_info_for_git("jump_boost")[/code]
func get_module_info_for_git(module_id: String) -> Dictionary:
	var available_modules = module_manager.get_available_modules()
	if not module_id in available_modules:
		return {}
	
	var module_info = available_modules[module_id]
	return {
		"config": module_info.config,
		"path": module_info.path,
		"destination": git_service.get_default_module_folder() + "/" + module_id
	}

## Check if module can be copied for git integration taking [module_id] [br]
## [code]if module_ops.can_copy_module_for_git("jump_boost"):[/code]
func can_copy_module_for_git(module_id: String) -> bool:
	var available_modules = module_manager.get_available_modules()
	if not module_id in available_modules:
		return false
	
	var module_info = available_modules[module_id]
	var source_path = module_info.path
	
	return DirAccess.dir_exists_absolute(source_path)

## Update module manifest with repository URL taking [module_id] and [repository_url] [br]
## [code]var result = module_ops.update_module_manifest_repository("jump_boost", "https://github.com/user/repo.git")[/code]
func update_module_manifest_repository(module_id: String, repository_url: String) -> Result:
	var available_modules = module_manager.get_available_modules()
	if not module_id in available_modules:
		return Result.failure("Module not found: " + module_id)
	
	var module_path = available_modules[module_id].path
	return git_service.update_manifest_repository(module_path, repository_url)

## Wrap long text for tooltip display taking [text] and [max_chars_per_line] [br]
## [code]var wrapped = module_ops.wrap_tooltip_text("Long description", 50)[/code]
func wrap_tooltip_text(text: String, max_chars_per_line: int = 50) -> String:
	if text.length() <= max_chars_per_line:
		return text
	
	var words = text.split(" ")
	var lines = []
	var current_line = ""
	
	for word in words:
		if current_line.length() + word.length() + 1 <= max_chars_per_line:
			if current_line.length() > 0:
				current_line += " "
			current_line += word
		else:
			if current_line.length() > 0:
				lines.append(current_line)
			current_line = word
	
	if current_line.length() > 0:
		lines.append(current_line)
	
	return "\n".join(lines) 