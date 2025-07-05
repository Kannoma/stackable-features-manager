## Git settings and client manager for stackable features [br]
## Handles git client configuration, settings persistence, and client integration
##
class_name GitManager
extends RefCounted

## Signals for git operations
signal git_operation_completed(success: bool, message: String)
signal git_settings_configured()
signal repository_cloned(success: bool, path: String)

## Git settings
var git_client_path: String = ""
var default_module_folder: String = ""

## Service dependencies
var git_repository_service: GitRepositoryService
var manifest_manager: ManifestManager

## Initialize git manager and load settings [br]
## [code]var git_manager = GitManager.new()[/code]
func _init() -> void:
	git_repository_service = GitRepositoryService.new()
	manifest_manager = ManifestManager.new()
	load_git_settings()

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
## [code]if git_manager.are_git_settings_configured():[/code]
func are_git_settings_configured() -> bool:
	return git_client_path != "" and default_module_folder != "" and FileAccess.file_exists(git_client_path) and DirAccess.dir_exists_absolute(default_module_folder)

## Set git client path taking [path] [br]
## [code]git_manager.set_git_client_path("C:/Program Files/Git/bin/git.exe")[/code]
func set_git_client_path(path: String) -> void:
	git_client_path = path
	save_git_settings()

## Set default module folder taking [path] [br]
## [code]git_manager.set_default_module_folder("C:/Dev/Modules")[/code]
func set_default_module_folder(path: String) -> void:
	default_module_folder = path
	save_git_settings()

## Get git client path [br]
## [code]var path = git_manager.get_git_client_path()[/code]
func get_git_client_path() -> String:
	return git_client_path

## Get default module folder [br]
## [code]var folder = git_manager.get_default_module_folder()[/code]
func get_default_module_folder() -> String:
	return default_module_folder

## Copy module files recursively from source to destination, preserving git history taking [source_path] and [dest_path] [br]
## [code]var result = copy_module_files("source/path", "dest/path")[/code]
func copy_module_files(source_path: String, dest_path: String) -> Result:
	var source_dir = DirAccess.open(source_path)
	if not source_dir:
		return Result.failure("Cannot open source directory: " + source_path)
	
	var dest_dir = DirAccess.open(dest_path)
	if not dest_dir:
		return Result.failure("Cannot open destination directory: " + dest_path)
	
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
## [code]var result = git_manager.sync_module_to_repository("stackable_features/jump_boost", "C:/Dev/jump_boost", "https://github.com/user/repo.git")[/code]
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
			var clone_result = git_repository_service.clone_repository(repository_url, dest_path)
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
			var init_result = git_repository_service.initialize_repository(dest_path)
			if init_result.is_error():
				return init_result
			
			return Result.success("Repository initialized successfully")

## Initialize and connect repository taking [path] and [repository_url] [br]
## [code]var result = git_manager.initialize_and_connect_repository("C:/Dev/jump_boost", "https://github.com/user/repo.git")[/code]
## @deprecated Use sync_module_to_repository instead for better handling of existing directories
func initialize_and_connect_repository(path: String, repository_url: String) -> Result:
	# If repository URL is provided, clone the existing repository directly
	if repository_url != "":
		# Remove the directory if it exists (we'll clone fresh)
		if DirAccess.dir_exists_absolute(path):
			var dir = DirAccess.open(path.get_base_dir())
			if dir:
				dir.remove(path.get_file())
		
		# Clone the repository directly - this gets us the exact state of the remote
		var clone_result = git_repository_service.clone_repository(repository_url, path)
		if clone_result.is_error():
			return clone_result
		
		print("Repository cloned successfully to: ", path)
		return Result.success("Repository cloned and connected successfully")
	else:
		# No repository URL - just initialize empty repository
		var init_result = git_repository_service.initialize_repository(path)
		if init_result.is_error():
			return init_result
		
		return Result.success("Repository initialized successfully")

## Open folder in configured git client taking [path] [br]
## [code]git_manager.open_in_git_client("C:/Dev/jump_boost")[/code]
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

## Update manifest file with repository URL taking [module_path] and [repository_url] [br]
## [code]var result = git_manager.update_manifest_repository("path/to/module", "https://github.com/user/repo.git")[/code]
func update_manifest_repository(module_path: String, repository_url: String) -> Result:
	var manifest_path = module_path + "/manifest.json"
	return manifest_manager.update_repository_url(manifest_path, repository_url)

## Clone repository to destination path taking [repository_url] and [dest_path] [br]
## [code]var result = git_manager.clone_repository("https://github.com/user/repo", "res://stackable_features/repo")[/code]
func clone_repository(repository_url: String, dest_path: String) -> Result:
	var clone_result = git_repository_service.clone_repository(repository_url, dest_path)
	
	# Emit signal for backward compatibility
	if clone_result.is_ok():
		repository_cloned.emit(true, dest_path)
	else:
		repository_cloned.emit(false, dest_path)
	
	return clone_result

## Extract module name from repository URL taking [repository_url] [br]
## [code]var name = git_manager.extract_module_name_from_url("https://github.com/user/repo")[/code]
func extract_module_name_from_url(repository_url: String) -> String:
	return git_repository_service.extract_module_name_from_url(repository_url) 