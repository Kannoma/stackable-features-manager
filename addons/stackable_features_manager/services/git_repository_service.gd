## Git repository service for pure git operations [br]
## Handles git clone, init, remote management, and other core git functionality
##
class_name GitRepositoryService
extends RefCounted

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
## [code]var result = await git_service.clone_repository("https://github.com/user/repo.git", "C:/Dev/repo")[/code]
func clone_repository(repository_url: String, dest_path: String) -> Result:
	# Convert res:// path to absolute path if needed
	var absolute_dest_path = dest_path
	if dest_path.begins_with("res://"):
		absolute_dest_path = ProjectSettings.globalize_path(dest_path)
	
	var output = []
	var exit_code = OS.execute("git", ["clone", repository_url, absolute_dest_path], output, true, true)
	
	if exit_code == 0:
		return Result.success("Repository cloned successfully to: " + dest_path)
	else:
		var error_msg = "Git clone failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)

## Add remote repository taking [path] and [repository_url] [br]
## [code]var result = git_service.add_remote("C:/Dev/my_module", "https://github.com/user/repo.git")[/code]
func add_remote(path: String, repository_url: String, remote_name: String = "origin") -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	if repository_url == "":
		return Result.failure("Repository URL cannot be empty")
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "remote", "add", remote_name, repository_url], output, true, true)
	
	if exit_code == 0:
		return Result.success("Remote '" + remote_name + "' added successfully")
	else:
		var error_msg = "Git remote add failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
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

## Get current branch name taking [path] [br]
## [code]var result = git_service.get_current_branch("C:/Dev/my_module")[/code]
func get_current_branch(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "branch", "--show-current"], output, true, true)
	
	if exit_code == 0 and output.size() > 0:
		var branch_name = output[0].strip_edges()
		return Result.success(branch_name)
	else:
		return Result.failure("Could not determine current branch")

## Get remote URL taking [path] and [remote_name] [br]
## [code]var result = git_service.get_remote_url("C:/Dev/my_module", "origin")[/code]
func get_remote_url(path: String, remote_name: String = "origin") -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "remote", "get-url", remote_name], output, true, true)
	
	if exit_code == 0 and output.size() > 0:
		var remote_url = output[0].strip_edges()
		return Result.success(remote_url)
	else:
		return Result.failure("Could not get remote URL for: " + remote_name)

## Check git status taking [path] [br]
## [code]var result = git_service.get_status("C:/Dev/my_module")[/code]
func get_status(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "status", "--porcelain"], output, true, true)
	
	if exit_code == 0:
		return Result.success(output)
	else:
		return Result.failure("Could not get git status")

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

## Stage all files in repository taking [path] [br]
## [code]var result = git_service.stage_all_files("C:/Dev/my_module")[/code]
func stage_all_files(path: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "add", "."], output, true, true)
	
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

## Fetch from remote repository taking [path] and [remote_name] [br]
## [code]var result = git_service.fetch_remote("C:/Dev/my_module", "origin")[/code]
func fetch_remote(path: String, remote_name: String = "origin") -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "fetch", remote_name], output, true, true)
	
	if exit_code == 0:
		return Result.success("Fetched from remote successfully")
	else:
		var error_msg = "Git fetch failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)

## Set up branch to track remote taking [path], [local_branch], and [remote_branch] [br]
## [code]var result = git_service.set_upstream_branch("C:/Dev/my_module", "main", "origin/main")[/code]
func set_upstream_branch(path: String, local_branch: String, remote_branch: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "branch", "--set-upstream-to=" + remote_branch, local_branch], output, true, true)
	
	if exit_code == 0:
		return Result.success("Upstream branch set successfully")
	else:
		var error_msg = "Git set upstream failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg)

## Check if remote branch exists taking [path] and [remote_branch] [br]
## [code]var result = git_service.remote_branch_exists("C:/Dev/my_module", "origin/main")[/code]
func remote_branch_exists(path: String, remote_branch: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "ls-remote", "--heads", "origin", remote_branch.split("/")[1]], output, true, true)
	
	if exit_code == 0 and output.size() > 0:
		return Result.success("Remote branch exists")
	else:
		return Result.failure("Remote branch does not exist")

## Pull with allow unrelated histories taking [path] and [remote_branch] [br]
## [code]var result = git_service.pull_allow_unrelated_histories("C:/Dev/my_module", "origin/main")[/code]
func pull_allow_unrelated_histories(path: String, remote_branch: String) -> Result:
	if not DirAccess.dir_exists_absolute(path):
		return Result.failure("Directory does not exist: " + path)
	
	var parts = remote_branch.split("/")
	if parts.size() != 2:
		return Result.failure("Invalid remote branch format: " + remote_branch)
	
	var remote_name = parts[0]
	var branch_name = parts[1]
	
	var output = []
	var exit_code = OS.execute("git", ["-C", path, "pull", remote_name, branch_name, "--allow-unrelated-histories", "--no-edit"], output, true, true)
	
	if exit_code == 0:
		return Result.success("Pulled with unrelated histories merged successfully")
	else:
		var error_msg = "Git pull with unrelated histories failed with exit code: " + str(exit_code)
		if output.size() > 0:
			error_msg += "\nOutput: " + "\n".join(output)
		return Result.failure(error_msg) 