@tool
extends RefCounted
class_name ModuleGenerator

static func create_module(module_name: String, module_id: String, author: String, description: String) -> bool:
	var module_path = "stackable_features/" + module_id
	
	# Create directory
	print("Creating module at path: ", module_path)
	if not DirAccess.dir_exists_absolute(module_path):
		var dir = DirAccess.open(".")
		if dir.make_dir_recursive(module_path) != OK:
			print("ERROR: Failed to create directory: ", module_path)
			return false
		print("Successfully created directory: ", module_path)
	else:
		print("Directory already exists: ", module_path)
	
	# Generate class names
	var module_class = _to_pascal_case(module_name) + "Module"
	var api_class = _to_pascal_case(module_name) + "API"
	var config_class = _to_pascal_case(module_name) + "Config"
	
	# Create variables dictionary
	var variables = {
		"MODULE_NAME": module_name,
		"MODULE_ID": module_id,
		"MODULE_CLASS": module_class,
		"API_CLASS": api_class,
		"CONFIG_CLASS": config_class,
		"AUTHOR": author,
		"DESCRIPTION": description
	}
	
	# Generate all files
	print("Generating manifest...")
	if not _generate_from_template(module_path, "manifest_template.md", "manifest.json", variables):
		print("ERROR: Failed to generate manifest")
		return false
	
	print("Generating README...")
	if not _generate_readme(module_path, variables):
		print("ERROR: Failed to generate README")
		return false
	
	print("Generating main module...")
	if not _generate_from_template(module_path, "module_template.md", "main.md", variables):
		print("ERROR: Failed to generate main module")
		return false
	
	print("Generating API...")
	if not _generate_from_template(module_path, "api_template.md", "api.md", variables):
		print("ERROR: Failed to generate API")
		return false
	
	print("Generating config...")
	if not _generate_from_template(module_path, "config_template.md", "config.md", variables):
		print("ERROR: Failed to generate config")
		return false
	
	print("Generating config default...")
	if not _generate_config_default(module_path, variables):
		print("ERROR: Failed to generate config default")
		return false
	
	# Convert .md extensions to proper extensions
	print("Converting extensions...")
	if not _convert_extensions(module_path):
		print("ERROR: Failed to convert extensions")
		return false
	
	# Force Godot to refresh the filesystem so it can discover the new classes
	print("Refreshing filesystem...")
	EditorInterface.get_resource_filesystem().scan()
	
	# The filesystem scan should be sufficient - reimport can cause conflicts
	print("Filesystem scan initiated - classes will be registered automatically")
	
	print("Module generation completed successfully!")
	return true

static func _generate_from_template(module_path: String, template_name: String, output_name: String, variables: Dictionary) -> bool:
	var template_path = "addons/stackable_features_manager/templates/" + template_name
	var template_file = FileAccess.open(template_path, FileAccess.READ)
	if not template_file:
		print("Failed to open template: " + template_path)
		return false
	
	var template_content = template_file.get_as_text()
	template_file.close()
	
	# Replace variables
	var content = template_content
	for key in variables:
		content = content.replace("{" + key + "}", str(variables[key]))
	
	# Write file
	var output_path = module_path + "/" + output_name
	var output_file = FileAccess.open(output_path, FileAccess.WRITE)
	if not output_file:
		print("Failed to create file: " + output_path)
		return false
	
	output_file.store_string(content)
	output_file.close()
	
	print("Generated: " + output_path)
	return true



static func _generate_readme(module_path: String, variables: Dictionary) -> bool:
	var template_path = "addons/stackable_features_manager/templates/readme_template.md"
	var template_file = FileAccess.open(template_path, FileAccess.READ)
	if not template_file:
		print("Failed to open README template")
		return false
	
	var template_content = template_file.get_as_text()
	template_file.close()
	
	# Replace variables
	var content = template_content
	for key in variables:
		content = content.replace("{" + key + "}", str(variables[key]))
	
	# Write README
	var readme_path = module_path + "/README.md"
	var readme_file = FileAccess.open(readme_path, FileAccess.WRITE)
	if not readme_file:
		print("Failed to create README")
		return false
	
	readme_file.store_string(content)
	readme_file.close()
	
	print("Generated: " + readme_path)
	return true

static func _generate_config_default(module_path: String, variables: Dictionary) -> bool:
	var config_content = '[gd_resource type="Resource" format=3]\n\n[resource]\nenabled = true\n'
	
	var config_path = module_path + "/config_default.tres"
	var config_file = FileAccess.open(config_path, FileAccess.WRITE)
	if not config_file:
		return false
	
	config_file.store_string(config_content)
	config_file.close()
	
	print("Generated: " + config_path)
	return true

static func _convert_extensions(module_path: String) -> bool:
	var conversions = [
		{"from": "main.md", "to": "main.gd"},
		{"from": "api.md", "to": "api.gd"},
		{"from": "config.md", "to": "config.gd"}
	]
	
	for conversion in conversions:
		var old_path = module_path + "/" + conversion.from
		var new_path = module_path + "/" + conversion.to
		
		if FileAccess.file_exists(old_path):
			var dir = DirAccess.open(module_path)
			if dir.rename(conversion.from, conversion.to) != OK:
				print("Failed to rename " + conversion.from + " to " + conversion.to)
				return false
			print("Renamed: " + conversion.from + " -> " + conversion.to)
	
	return true

static func _to_pascal_case(text: String) -> String:
	var words = text.split("_")
	var result = ""
	for word in words:
		if word.length() > 0:
			result += word.capitalize()
	return result 