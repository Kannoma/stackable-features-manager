## Module service for file operations and module management [br]
## Handles module copying, validation, directory operations, and file system tasks
##
class_name ModuleService
extends RefCounted

## Copy module from source to destination taking [source_path] and [dest_path] [br]
## [code]var result = module_service.copy_module("source/path", "dest/path")[/code]
func copy_module(source_path: String, dest_path: String) -> Result:
	if not DirAccess.dir_exists_absolute(source_path):
		return Result.failure("Source directory does not exist: " + source_path)
	
	# Create destination directory if it doesn't exist
	var dest_dir = DirAccess.open(dest_path.get_base_dir())
	if not dest_dir:
		dest_dir = DirAccess.open(".")
	
	if not dest_dir.dir_exists(dest_path):
		var error = dest_dir.make_dir_recursive(dest_path)
		if error != OK:
			return Result.failure("Failed to create destination directory: " + dest_path)
	
	# Copy all files and directories
	var copy_result = copy_directory_recursive(source_path, dest_path)
	if copy_result.is_error():
		return copy_result
	
	return Result.success("Module copied successfully from " + source_path + " to " + dest_path)

## Recursively copy directory contents taking [source] and [destination] [br]
## [code]var result = module_service.copy_directory_recursive("source", "dest")[/code]
func copy_directory_recursive(source: String, destination: String) -> Result:
	var source_dir = DirAccess.open(source)
	if not source_dir:
		return Result.failure("Failed to open source directory: " + source)
	
	var dest_dir = DirAccess.open(destination.get_base_dir())
	if not dest_dir:
		return Result.failure("Failed to open destination parent directory: " + destination.get_base_dir())
	
	if not dest_dir.dir_exists(destination):
		dest_dir.make_dir_recursive(destination)
	
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()
	
	while file_name != "":
		var source_file = source + "/" + file_name
		var dest_file = destination + "/" + file_name
		
		# Skip .uid files (Godot metadata files)
		if file_name.ends_with(".uid"):
			file_name = source_dir.get_next()
			continue
		
		if source_dir.current_is_dir():
			var recursive_result = copy_directory_recursive(source_file, dest_file)
			if recursive_result.is_error():
				source_dir.list_dir_end()
				return recursive_result
		else:
			if source_dir.copy(source_file, dest_file) != OK:
				source_dir.list_dir_end()
				return Result.failure("Failed to copy file: " + source_file)
		
		file_name = source_dir.get_next()
	
	source_dir.list_dir_end()
	return Result.success("Directory copied successfully")

## Validate module directory structure taking [module_path] [br]
## [code]var result = module_service.validate_module_structure("path/to/module")[/code]
func validate_module_structure(module_path: String) -> Result:
	if not DirAccess.dir_exists_absolute(module_path):
		return Result.failure("Module directory does not exist: " + module_path)
	
	# Check for manifest.json
	var manifest_path = module_path + "/manifest.json"
	if not FileAccess.file_exists(manifest_path):
		return Result.failure("Module missing manifest.json file")
	
	# Check for api.gd
	var api_path = module_path + "/api.gd"
	if not FileAccess.file_exists(api_path):
		return Result.failure("Module missing api.gd file")
	
	# Check for config.gd
	var config_path = module_path + "/config.gd"
	if not FileAccess.file_exists(config_path):
		return Result.failure("Module missing config.gd file")
	
	return Result.success("Module structure is valid")

## Create module directory structure taking [module_path] [br]
## [code]var result = module_service.create_module_directory("path/to/new_module")[/code]
func create_module_directory(module_path: String) -> Result:
	var dir = DirAccess.open(".")
	if not dir:
		return Result.failure("Failed to access file system")
	
	var error = dir.make_dir_recursive(module_path)
	if error != OK:
		return Result.failure("Failed to create module directory: " + module_path)
	
	return Result.success("Module directory created successfully")

## Check if path is valid for module operations taking [path] [br]
## [code]var result = module_service.validate_path("C:/Dev/modules")[/code]
func validate_path(path: String) -> Result:
	if path == "":
		return Result.failure("Path cannot be empty")
	
	# Check if parent directory exists (for creating new directories)
	var parent_dir = path.get_base_dir()
	if not DirAccess.dir_exists_absolute(parent_dir):
		return Result.failure("Parent directory does not exist: " + parent_dir)
	
	return Result.success("Path is valid")

## Get module size in bytes taking [module_path] [br]
## [code]var result = module_service.get_module_size("path/to/module")[/code]
func get_module_size(module_path: String) -> Result:
	if not DirAccess.dir_exists_absolute(module_path):
		return Result.failure("Module directory does not exist: " + module_path)
	
	var total_size = calculate_directory_size(module_path)
	return Result.success(total_size)

## Calculate directory size recursively taking [path] [br]
## [code]var size = module_service.calculate_directory_size("path/to/dir")[/code]
func calculate_directory_size(path: String) -> int:
	var total_size = 0
	var dir = DirAccess.open(path)
	if not dir:
		return 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var file_path = path + "/" + file_name
		
		if dir.current_is_dir():
			total_size += calculate_directory_size(file_path)
		else:
			var file = FileAccess.open(file_path, FileAccess.READ)
			if file:
				total_size += file.get_length()
				file.close()
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return total_size

## Clean up temporary files in module directory taking [module_path] [br]
## [code]var result = module_service.cleanup_temp_files("path/to/module")[/code]
func cleanup_temp_files(module_path: String) -> Result:
	if not DirAccess.dir_exists_absolute(module_path):
		return Result.failure("Module directory does not exist: " + module_path)
	
	var files_cleaned = 0
	files_cleaned += remove_files_with_extension(module_path, ".uid")
	files_cleaned += remove_files_with_extension(module_path, ".tmp")
	files_cleaned += remove_files_with_extension(module_path, ".bak")
	
	return Result.success("Cleaned " + str(files_cleaned) + " temporary files")

## Remove files with specific extension taking [path] and [extension] [br]
## [code]var count = module_service.remove_files_with_extension("path", ".uid")[/code]
func remove_files_with_extension(path: String, extension: String) -> int:
	var files_removed = 0
	var dir = DirAccess.open(path)
	if not dir:
		return 0
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	
	while file_name != "":
		var file_path = path + "/" + file_name
		
		if dir.current_is_dir():
			files_removed += remove_files_with_extension(file_path, extension)
		elif file_name.ends_with(extension):
			if dir.remove(file_path) == OK:
				files_removed += 1
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	return files_removed

## Copy module files into existing git repository taking [source_path] and [dest_path] [br]
## [code]var result = module_service.copy_module_to_git_repo("source/path", "dest/path")[/code]
func copy_module_to_git_repo(source_path: String, dest_path: String) -> Result:
	if not DirAccess.dir_exists_absolute(source_path):
		return Result.failure("Source directory does not exist: " + source_path)
	
	if not DirAccess.dir_exists_absolute(dest_path):
		return Result.failure("Destination directory does not exist: " + dest_path)
	
	# Copy all files and directories, but preserve git files
	var copy_result = copy_directory_preserving_git(source_path, dest_path)
	if copy_result.is_error():
		return copy_result
	
	return Result.success("Module copied successfully to git repository")

## Copy directory contents while preserving git files taking [source] and [destination] [br]
## [code]var result = module_service.copy_directory_preserving_git("source", "dest")[/code]
func copy_directory_preserving_git(source: String, destination: String) -> Result:
	var source_dir = DirAccess.open(source)
	if not source_dir:
		return Result.failure("Failed to open source directory: " + source)
	
	source_dir.list_dir_begin()
	var file_name = source_dir.get_next()
	
	while file_name != "":
		var source_file = source + "/" + file_name
		var dest_file = destination + "/" + file_name
		
		# Skip .uid files (Godot metadata files)
		if file_name.ends_with(".uid"):
			file_name = source_dir.get_next()
			continue
		
		# Skip git-related files/directories to preserve repository state
		if file_name.begins_with(".git"):
			file_name = source_dir.get_next()
			continue
		
		if source_dir.current_is_dir():
			# Create directory if it doesn't exist
			var dest_dir = DirAccess.open(destination)
			if not dest_dir.dir_exists(file_name):
				dest_dir.make_dir(file_name)
			
			var recursive_result = copy_directory_preserving_git(source_file, dest_file)
			if recursive_result.is_error():
				source_dir.list_dir_end()
				return recursive_result
		else:
			if source_dir.copy(source_file, dest_file) != OK:
				source_dir.list_dir_end()
				return Result.failure("Failed to copy file: " + source_file)
		
		file_name = source_dir.get_next()
	
	source_dir.list_dir_end()
	return Result.success("Directory copied successfully while preserving git files") 