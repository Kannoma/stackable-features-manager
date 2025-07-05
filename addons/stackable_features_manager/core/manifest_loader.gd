## Module: ManifestLoader
## Purpose: Loads and parses feature manifests from simplified JSON format with git integration
## Dependencies: FeatureConfig
##

# Utility class for loading feature manifests from JSON
# Provides a clean, simple alternative to complex .tres resource files with git integration

@tool
class_name ManifestLoader
extends RefCounted

## Constants
const MANIFEST_NAME = "manifest.json"

## Loads a feature manifest from the specified module path taking [module_path] [br]
## [code]var config = ManifestLoader.load_manifest("stackable_features/my_module")[/code]
static func load_manifest(module_path: String) -> FeatureConfig:
	var json_path = module_path + "/" + MANIFEST_NAME
	if not FileAccess.file_exists(json_path):
		print("ManifestLoader: No manifest.json found in ", module_path)
		return null
	
	print("ManifestLoader: Loading manifest from ", json_path)
	
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("ManifestLoader: Cannot open manifest: ", json_path)
		return null
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	if parse_result != OK:
		print("ManifestLoader: Failed to parse JSON manifest: ", json_path)
		return null
	
	var data = json.data
	if not data is Dictionary:
		print("ManifestLoader: JSON manifest must be an object: ", json_path)
		return null
	
	var config = create_feature_config_from_json(data, module_path)
	if config:
		print("ManifestLoader: Successfully created config for module: ", config.id)
	return config

## Creates a FeatureConfig from JSON data taking [data] and [module_path] [br]
## [code]var config = ManifestLoader.create_feature_config_from_json(json_data, "module_path")[/code]
static func create_feature_config_from_json(data: Dictionary, module_path: String) -> FeatureConfig:
	var config = FeatureConfig.new()
	
	# Set basic properties
	config.id = data.get("id", "")
	config.name = data.get("name", "")
	config.version = data.get("version", "1.0.0")
	config.description = data.get("description", "")
	config.author = data.get("author", "")
	config.entry_point = data.get("entry_point", "")
	
	# Set git integration
	config.repository = data.get("repository", "")
	
	# Handle requires array - no more Array[String] syntax!
	var requires = data.get("requires", [])
	if requires is Array:
		var typed_requires: Array[String] = []
		for item in requires:
			if item is String:
				typed_requires.append(item)
		config.requires = typed_requires
	
	# Handle engine_versions array - no more Array[String] syntax!
	var engine_versions = data.get("engine_versions", ["4.3", "4.4"])
	if engine_versions is Array:
		var typed_versions: Array[String] = []
		for item in engine_versions:
			if item is String:
				typed_versions.append(item)
		config.engine_versions = typed_versions
	
	# Load module config if specified
	var config_file = data.get("config_file", "")
	if config_file != "":
		var config_path = module_path + "/" + config_file
		if FileAccess.file_exists(config_path):
			var module_config = load(config_path)
			if module_config and module_config is ModuleConfig:
				config.module_config = module_config
			else:
				print("ManifestLoader: Failed to load config file: ", config_path)
		else:
			print("ManifestLoader: Config file not found: ", config_path)
	
	return config 