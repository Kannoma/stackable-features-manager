## Manifest manager for handling manifest.json file operations [br]
## Provides reading, writing, and updating of module manifest files
##
class_name ManifestManager
extends RefCounted

## Read manifest from file taking [manifest_path] [br]
## [code]var result = manifest_manager.read_manifest("path/to/manifest.json")[/code]
func read_manifest(manifest_path: String) -> Result:
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if not file:
		return Result.failure("Failed to open manifest file: " + manifest_path)
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		return Result.failure("Failed to parse manifest JSON: " + manifest_path)
	
	var data = json.data
	if not data is Dictionary:
		return Result.failure("Manifest is not a valid JSON object: " + manifest_path)
	
	return Result.success(data)

## Write manifest to file taking [manifest_path] and [data] [br]
## [code]var result = manifest_manager.write_manifest("path/to/manifest.json", manifest_data)[/code]
func write_manifest(manifest_path: String, data: Dictionary) -> Result:
	var json_string = JSON.stringify(data, "\t")
	
	var file = FileAccess.open(manifest_path, FileAccess.WRITE)
	if not file:
		return Result.failure("Failed to open manifest for writing: " + manifest_path)
	
	file.store_string(json_string)
	file.close()
	
	return Result.success(null)

## Update repository URL in manifest taking [manifest_path] and [repository_url] [br]
## [code]var result = manifest_manager.update_repository_url("path/to/manifest.json", "https://github.com/user/repo.git")[/code]
func update_repository_url(manifest_path: String, repository_url: String) -> Result:
	# Validate input - don't update with empty URLs
	if repository_url.strip_edges() == "":
		return Result.failure("Repository URL cannot be empty")
	
	# Read the original file content to preserve formatting
	var file = FileAccess.open(manifest_path, FileAccess.READ)
	if not file:
		return Result.failure("Failed to open manifest file: " + manifest_path)
	
	var original_content = file.get_as_text()
	file.close()
	
	# Parse JSON to check if repository already exists
	var json = JSON.new()
	var parse_result = json.parse(original_content)
	if parse_result != OK:
		return Result.failure("Failed to parse manifest JSON: " + manifest_path)
	
	var data = json.data
	if not data is Dictionary:
		return Result.failure("Manifest is not a valid JSON object: " + manifest_path)
	
	# If repository already exists, don't modify the file
	if data.has("repository"):
		return Result.success(null)
	
	# Add repository field before the closing brace, preserving formatting
	var lines = original_content.split("\n")
	var updated_lines = []
	var last_property_index = -1
	
	# Find the last property line (before closing brace)
	for i in range(lines.size() - 1, -1, -1):
		var line = lines[i].strip_edges()
		if line.ends_with(",") or (line.ends_with('"') and line.contains(":")):
			last_property_index = i
			break
	
	# Build the updated content
	for i in range(lines.size()):
		if i == last_property_index:
			# Add comma to the last property if it doesn't have one
			var line = lines[i]
			if not line.strip_edges().ends_with(","):
				line = line.rstrip("\r\n") + ","
			updated_lines.append(line)
			# Add repository field with same indentation as other fields
			var indent = ""
			var stripped = lines[i].lstrip("\t ")
			var original_length = lines[i].length()
			var stripped_length = stripped.length()
			for j in range(original_length - stripped_length):
				indent += lines[i][j]
			updated_lines.append(indent + '"repository": "' + repository_url + '"')
		else:
			updated_lines.append(lines[i])
	
	var updated_content = "\n".join(updated_lines)
	
	# Write the updated content back
	var write_file = FileAccess.open(manifest_path, FileAccess.WRITE)
	if not write_file:
		return Result.failure("Failed to open manifest for writing: " + manifest_path)
	
	write_file.store_string(updated_content)
	write_file.close()
	
	return Result.success(null)

## Validate manifest structure taking [data] [br]
## [code]var result = manifest_manager.validate_manifest(manifest_data)[/code]
func validate_manifest(data: Dictionary) -> Result:
	# Check required fields
	var required_fields = ["id", "name", "version", "description"]
	
	for field in required_fields:
		if not data.has(field):
			return Result.failure("Missing required field: " + field)
		
		if data[field] == "":
			return Result.failure("Empty required field: " + field)
	
	# Validate ID format (should be lowercase, alphanumeric with hyphens and underscores)
	var id_regex = RegEx.new()
	id_regex.compile("^[a-z0-9_-]+$")
	if not id_regex.search(data["id"]):
		return Result.failure("Invalid ID format. Use lowercase letters, numbers, hyphens, and underscores only.")
	
	return Result.success(null)

## Extract module name from manifest taking [data] [br]
## [code]var name = manifest_manager.extract_module_name(manifest_data)[/code]
func extract_module_name(data: Dictionary) -> String:
	return data.get("name", "")

## Extract module ID from manifest taking [data] [br]
## [code]var id = manifest_manager.extract_module_id(manifest_data)[/code]
func extract_module_id(data: Dictionary) -> String:
	return data.get("id", "")

## Extract repository URL from manifest taking [data] [br]
## [code]var url = manifest_manager.extract_repository_url(manifest_data)[/code]
func extract_repository_url(data: Dictionary) -> String:
	return data.get("repository", "")

## Check if manifest has repository URL taking [data] [br]
## [code]if manifest_manager.has_repository_url(manifest_data):[/code]
func has_repository_url(data: Dictionary) -> bool:
	var repo_url = data.get("repository", "")
	return repo_url != "" 