## Module: ModuleManagerDock
## Purpose: UI dock for managing stackable feature modules in the editor with git integration
## Dependencies: ModuleManager
##

# Editor dock UI for managing feature modules
# Provides a simple interface to load and unload modules with git integration

@tool
extends Control

## UI References
@onready var module_list: VBoxContainer = $VBoxContainer/ScrollContainer/ModuleList
@onready var import_button: Button = $VBoxContainer/ButtonContainer/ImportButton
@onready var refresh_button: Button = $VBoxContainer/ButtonContainer/RefreshButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

## Service dependencies
var module_manager: ModuleManager
var git_manager: GitManager
var module_operations: ModuleOperations
var git_workflow_service: GitWorkflowService
var dialog_manager: DialogManager

## HTTP request node for GitHub API calls
var http_request: HTTPRequest

## Initialize the UI dock [br]
## [code]_ready()[/code]
func _ready() -> void:
	setup_services()
	setup_ui()
	setup_dialogs()
	connect_signals()
	refresh_modules()

## Setup service dependencies [br]
## [code]setup_services()[/code]
func setup_services() -> void:
	git_manager = GitManager.new()
	
	module_manager = ModuleManager.new()
	add_child(module_manager)
	
	# Create HTTPRequest node for GitHub API calls
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	module_operations = ModuleOperations.new(module_manager, git_manager, http_request)
	git_workflow_service = GitWorkflowService.new(git_manager, module_operations)
	dialog_manager = DialogManager.new(self)

## Setup the UI components [br]
## [code]setup_ui()[/code]
func setup_ui() -> void:
	import_button.pressed.connect(_on_import_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	status_label.text = "Ready"

## Setup all dialogs [br]
## [code]setup_dialogs()[/code]
func setup_dialogs() -> void:
	dialog_manager.create_all_dialogs()
	dialog_manager.connect_signals(self)

## Connect service signals [br]
## [code]connect_signals()[/code]
func connect_signals() -> void:
	# Module manager signals
	module_manager.modules_refreshed.connect(_on_modules_refreshed)
	module_manager.module_loaded.connect(_on_module_loaded)
	module_manager.module_unloaded.connect(_on_module_unloaded)
	
	# Git manager signals
	git_manager.git_settings_configured.connect(_on_git_settings_configured)
	git_manager.repository_cloned.connect(_on_repository_cloned)
	
	# Module operations signals
	module_operations.module_imported.connect(_on_module_imported)
	module_operations.module_copied.connect(_on_module_copied)
	
	# Git workflow signals
	git_workflow_service.workflow_completed.connect(_on_workflow_completed)
	git_workflow_service.git_settings_needed.connect(_on_git_settings_needed)
	git_workflow_service.repository_url_needed.connect(_on_repository_url_needed)



## Refresh the list of available modules [br]
## [code]refresh_modules()[/code]
func refresh_modules() -> void:
	status_label.text = "Refreshing modules..."
	module_manager.refresh_available_modules()

## Update the module list display with checkboxes and git buttons [br]
## [code]update_module_list()[/code]
func update_module_list() -> void:
	# Clear existing items
	for child in module_list.get_children():
		child.queue_free()
	
	var available_modules = module_manager.get_available_modules()
	
	for module_id in available_modules:
		var config = available_modules[module_id].config
		
		# Create horizontal container for checkbox and git button
		var hbox = HBoxContainer.new()
		
		# Create checkbox with module name (display name)
		var checkbox = CheckBox.new()
		checkbox.text = config.name
		checkbox.button_pressed = module_manager.is_module_enabled(module_id)
		checkbox.toggled.connect(func(pressed): _on_module_toggled(pressed, module_id))
		checkbox.add_theme_font_size_override("font_size", 14)
		checkbox.tooltip_text = module_operations.wrap_tooltip_text(config.description)
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Create git button
		var git_button = Button.new()
		git_button.icon = EditorInterface.get_editor_theme().get_icon("VcsBranches", "EditorIcons")
		git_button.tooltip_text = "Git Integration - Copy module to git folder and open in git client"
		git_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		git_button.pressed.connect(func(): _on_git_button_pressed(module_id))
		
		# Add to horizontal container
		hbox.add_child(checkbox)
		hbox.add_child(git_button)
		
		# Add to module list
		module_list.add_child(hbox)

## Update the state of a specific checkbox taking [module_id] and [state] [br]
## [code]_update_checkbox_state("jump_boost", true)[/code]
func _update_checkbox_state(module_id: String, state: bool) -> void:
	var available_modules = module_manager.get_available_modules()
	var module_name = available_modules[module_id].config.name
	
	for child in module_list.get_children():
		if child is HBoxContainer:
			var checkbox = child.get_child(0)
			if checkbox is CheckBox and checkbox.text == module_name:
				checkbox.button_pressed = state
				break



# =============================================================================
# SIGNAL HANDLERS
# =============================================================================

## Handle refresh button press [br]
## [code]_on_refresh_button_pressed()[/code]
func _on_refresh_button_pressed() -> void:
	refresh_modules()

## Handle import button press [br]
## [code]_on_import_button_pressed()[/code]
func _on_import_button_pressed() -> void:
	dialog_manager.show_import_dialog()

## Handle module checkbox toggle using the persistence system taking [pressed] and [module_id] [br]
## [code]_on_module_toggled(true, "jump_boost")[/code]
func _on_module_toggled(pressed: bool, module_id: String) -> void:
	var available_modules = module_manager.get_available_modules()
	var module_name = available_modules[module_id].config.name
	
	if pressed:
		status_label.text = "Enabling module: " + module_name
	else:
		status_label.text = "Disabling module: " + module_name
	
	# Use the persistence system to handle module state
	if module_manager.set_module_enabled(module_id, pressed):
		if pressed:
			status_label.text = "Module enabled successfully: " + module_name
		else:
			status_label.text = "Module disabled successfully: " + module_name
	else:
		if pressed:
			status_label.text = "Failed to enable module: " + module_name
		else:
			status_label.text = "Failed to disable module: " + module_name
		# Revert checkbox state on failure
		_update_checkbox_state(module_id, not pressed)

## Handle git button press for a module taking [module_id] [br]
## [code]_on_git_button_pressed("jump_boost")[/code]
func _on_git_button_pressed(module_id: String) -> void:
	status_label.text = "Starting git integration for " + module_id + "..."
	git_workflow_service.start_git_integration(module_id)

## Handle modules refreshed signal [br]
## [code]_on_modules_refreshed()[/code]
func _on_modules_refreshed() -> void:
	update_module_list()
	status_label.text = "Modules refreshed"

## Handle module loaded signal taking [module_id] [br]
## [code]_on_module_loaded("jump_boost")[/code]
func _on_module_loaded(module_id: String) -> void:
	update_module_list()

## Handle module unloaded signal taking [module_id] [br]
## [code]_on_module_unloaded("jump_boost")[/code]
func _on_module_unloaded(module_id: String) -> void:
	update_module_list()

## Handle git client path selection [br]
## [code]_on_git_client_selected("C:/Program Files/Git/bin/git.exe")[/code]
func _on_git_client_selected(path: String) -> void:
	git_manager.set_git_client_path(path)
	status_label.text = "Git client configured: " + path.get_file()
	git_workflow_service.continue_after_git_client_configured()

## Handle module folder selection [br]
## [code]_on_module_folder_selected("C:/Dev/Modules")[/code]
func _on_module_folder_selected(path: String) -> void:
	git_manager.set_default_module_folder(path)
	status_label.text = "Module folder configured: " + path.get_file()
	git_workflow_service.continue_after_module_folder_configured()

## Handle git client dialog canceled [br]
## [code]_on_git_client_dialog_canceled()[/code]
func _on_git_client_dialog_canceled() -> void:
	status_label.text = "Git client selection canceled"

## Handle module folder dialog canceled [br]
## [code]_on_module_folder_dialog_canceled()[/code]
func _on_module_folder_dialog_canceled() -> void:
	status_label.text = "Module folder selection canceled"

## Handle repository URL confirmed [br]
## [code]_on_repository_url_confirmed()[/code]
func _on_repository_url_confirmed() -> void:
	var repository_url = dialog_manager.get_repository_url_input()
	
	if repository_url == "":
		status_label.text = "Repository URL cannot be empty"
		return
	
	status_label.text = "Setting up git integration..."
	git_workflow_service.continue_with_repository_url(repository_url)

## Handle repository URL dialog canceled [br]
## [code]_on_repository_url_canceled()[/code]
func _on_repository_url_canceled() -> void:
	status_label.text = "Git integration canceled - repository URL not provided"
	git_workflow_service.cancel_workflow()

## Handle import dialog confirmed [br]
## [code]_on_import_confirmed()[/code]
func _on_import_confirmed() -> void:
	var repository_url = dialog_manager.get_import_url_input()
	
	var validation_result = module_operations.validate_import_url(repository_url)
	if validation_result.is_error():
		status_label.text = validation_result.get_error()
		return
	
	# Start the import process
	status_label.text = "Importing module..."
	await import_module_from_repository(repository_url)

## Handle import dialog canceled [br]
## [code]_on_import_canceled()[/code]
func _on_import_canceled() -> void:
	status_label.text = "Import canceled"

## Handle git settings configured signal [br]
## [code]_on_git_settings_configured()[/code]
func _on_git_settings_configured() -> void:
	status_label.text = "Git settings configured successfully"

## Handle repository cloned signal taking [success] and [path] [br]
## [code]_on_repository_cloned(true, "path")[/code]
func _on_repository_cloned(success: bool, path: String) -> void:
	if success:
		status_label.text = "Repository cloned successfully"
	else:
		status_label.text = "Failed to clone repository"

## Handle module imported signal taking [success] and [module_id] [br]
## [code]_on_module_imported(true, "jump_boost")[/code]
func _on_module_imported(success: bool, module_id: String) -> void:
	if success:
		status_label.text = "Module imported successfully: " + module_id
		refresh_modules()
	else:
		status_label.text = "Failed to import module"

## Handle module copied signal taking [success], [source_path] and [dest_path] [br]
## [code]_on_module_copied(true, "source", "dest")[/code]
func _on_module_copied(success: bool, source_path: String, dest_path: String) -> void:
	if success:
		status_label.text = "Module copied successfully to: " + dest_path.get_file()
	else:
		status_label.text = "Failed to copy module"

## Handle workflow completed signal taking [success] and [message] [br]
## [code]_on_workflow_completed(true, "Success message")[/code]
func _on_workflow_completed(success: bool, message: String) -> void:
	status_label.text = message

## Handle git settings needed signal taking [setting_type] [br]
## [code]_on_git_settings_needed("git_client")[/code]
func _on_git_settings_needed(setting_type: String) -> void:
	if setting_type == "git_client":
		status_label.text = "Please select your Git client executable..."
		dialog_manager.show_git_client_dialog()
	elif setting_type == "module_folder":
		status_label.text = "Please select default module folder..."
		dialog_manager.show_module_folder_dialog()

## Handle repository URL needed signal taking [module_id] [br]
## [code]_on_repository_url_needed("jump_boost")[/code]
func _on_repository_url_needed(module_id: String) -> void:
	status_label.text = "Repository URL needed for module: " + module_id
	dialog_manager.show_repository_url_dialog()

# =============================================================================
# HELPER METHODS
# =============================================================================

## Import a module from GitHub repository taking [repository_url] [br]
## [code]await import_module_from_repository("https://github.com/Kannoma/stackable-jump-boost")[/code]
func import_module_from_repository(repository_url: String) -> void:
	var result = await module_operations.import_module_from_github(repository_url)
	if result.is_ok():
		status_label.text = result.get_data()
	else:
		status_label.text = result.get_error()

## Deferred git client opening taking [path] [br]
## [code]_open_git_client_deferred("C:/Dev/jump_boost")[/code]
func _open_git_client_deferred(path: String) -> void:
	if git_manager.open_in_git_client(path):
		status_label.text = "Opened " + path.get_file() + " in git client"
	else:
		status_label.text = "Failed to open git client"

 