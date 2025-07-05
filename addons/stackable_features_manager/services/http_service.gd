## HTTP service for GitHub API calls and web requests [br]
## Handles all HTTP operations with consistent error handling and async patterns
##
class_name HttpService
extends RefCounted

## HTTP request node for making requests
var http_request: HTTPRequest

## Initialize HTTP service with request node taking [request_node] [br]
## [code]var service = HttpService.new(http_request_node)[/code]
func _init(request_node: HTTPRequest) -> void:
	http_request = request_node

## Fetch JSON data from URL taking [url] [br]
## [code]var result = await http_service.fetch_json("https://api.github.com/repos/user/repo")[/code]
func fetch_json(url: String) -> Result:
	var error = http_request.request(url)
	if error != OK:
		return Result.failure("HTTP request failed with error: " + str(error))
	
	var response = await http_request.request_completed
	
	var result_code = response[0]
	var response_code = response[1]
	var headers = response[2]
	var body = response[3]
	
	if response_code != 200:
		return Result.failure("HTTP request failed with status: " + str(response_code))
	
	var json_string = body.get_string_from_utf8()
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		return Result.failure("Failed to parse JSON response")
	
	return Result.success(json.data)

## Get GitHub repository information taking [repository_url] [br]
## [code]var result = await http_service.get_github_repo_info("https://github.com/user/repo")[/code]
func get_github_repo_info(repository_url: String) -> Result:
	var repo_info = extract_github_repo_info(repository_url)
	if repo_info.is_empty():
		return Result.failure("Invalid GitHub repository URL: " + repository_url)
	
	var api_url = "https://api.github.com/repos/" + repo_info.owner + "/" + repo_info.repo
	return await fetch_json(api_url)

## Get default branch from GitHub repository taking [repository_url] [br]
## [code]var result = await http_service.get_default_branch("https://github.com/user/repo")[/code]
func get_default_branch(repository_url: String) -> Result:
	var repo_result = await get_github_repo_info(repository_url)
	if repo_result.is_error():
		return repo_result
	
	var repo_data = repo_result.get_data()
	if not repo_data is Dictionary:
		return Result.failure("Invalid repository data received")
	
	var default_branch = repo_data.get("default_branch", "")
	if default_branch == "":
		return Result.failure("No default branch found in repository data")
	
	return Result.success(default_branch)

## Fetch manifest from GitHub repository taking [repository_url] [br]
## [code]var result = await http_service.fetch_manifest_from_github("https://github.com/user/repo")[/code]
func fetch_manifest_from_github(repository_url: String) -> Result:
	# Try to get default branch first
	var branch_result = await get_default_branch(repository_url)
	
	if branch_result.is_ok():
		var branch = branch_result.get_data()
		var manifest_result = await fetch_manifest_from_branch(repository_url, branch)
		if manifest_result.is_ok():
			return manifest_result
	
	# Fallback to common branch names
	var fallback_branches = ["main", "master", "develop", "dev"]
	for branch in fallback_branches:
		var manifest_result = await fetch_manifest_from_branch(repository_url, branch)
		if manifest_result.is_ok():
			return manifest_result
	
	return Result.failure("Could not fetch manifest.json from any branch")

## Fetch manifest from specific branch taking [repository_url] and [branch] [br]
## [code]var result = await http_service.fetch_manifest_from_branch("https://github.com/user/repo", "main")[/code]
func fetch_manifest_from_branch(repository_url: String, branch: String) -> Result:
	var manifest_url = convert_to_raw_manifest_url(repository_url, branch)
	if manifest_url == "":
		return Result.failure("Could not convert URL for branch: " + branch)
	
	return await fetch_json(manifest_url)

## Convert GitHub URL to raw manifest URL taking [repository_url] and [branch] [br]
## [code]var url = http_service.convert_to_raw_manifest_url("https://github.com/user/repo", "main")[/code]
func convert_to_raw_manifest_url(repository_url: String, branch: String = "main") -> String:
	var clean_url = repository_url
	if clean_url.ends_with(".git"):
		clean_url = clean_url.substr(0, clean_url.length() - 4)
	
	if clean_url.begins_with("https://github.com/"):
		var path = clean_url.substr(19)
		return "https://raw.githubusercontent.com/" + path + "/" + branch + "/manifest.json"
	
	return ""

## Extract GitHub repository owner and name from URL taking [repository_url] [br]
## [code]var info = http_service.extract_github_repo_info("https://github.com/user/repo")[/code]
func extract_github_repo_info(repository_url: String) -> Dictionary:
	var clean_url = repository_url
	if clean_url.ends_with(".git"):
		clean_url = clean_url.substr(0, clean_url.length() - 4)
	
	if clean_url.begins_with("https://github.com/"):
		var path = clean_url.substr(19)
		var parts = path.split("/")
		if parts.size() >= 2:
			return {
				"owner": parts[0],
				"repo": parts[1]
			}
	
	return {}

## Validate GitHub repository URL taking [url] [br]
## [code]if http_service.validate_github_url("https://github.com/user/repo"):[/code]
func validate_github_url(url: String) -> bool:
	return url.begins_with("https://github.com/") or url.begins_with("git@github.com:")

## Validate repository URL format taking [url] [br]
## [code]if http_service.validate_repository_url("https://github.com/user/repo"):[/code]
func validate_repository_url(url: String) -> bool:
	return url.begins_with("https://") or url.begins_with("git@") 