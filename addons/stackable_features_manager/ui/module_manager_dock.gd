## Module: ModuleManagerDock
## Purpose: Main UI dock for managing stackable feature modules in the editor
## Dependencies: ModuleManager (from core/registry/), UI components
##

# Editor dock UI for managing feature modules
# Coordinates between UI components and services with minimal direct responsibilities

@tool
extends Control

## UI References
@onready var module_list: VBoxContainer = $VBoxContainer/ScrollContainer/ModuleList
@onready var create_button: Button = $VBoxContainer/ButtonContainer/CreateButton
@onready var import_button: Button = $VBoxContainer/ButtonContainer/ImportButton
@onready var refresh_button: Button = $VBoxContainer/ButtonContainer/RefreshButton
@onready var status_label: Label = $VBoxContainer/StatusLabel

## UI Components
var status_manager: StatusManager
var import_workflow_manager: ImportWorkflowManager

## Service dependencies
var module_manager: ModuleManager
var git_service: GitService
var module_operations: ModuleOperations
var dialog_manager: DialogManager
var module_generator: ModuleGenerator

## HTTP request node for GitHub API calls
var http_request: HTTPRequest

## Initialize the UI dock [br]
## [code]_ready()[/code]
func _ready() -> void:
	setup_services()
	setup_components()
	setup_ui()
	setup_dialogs()
	connect_signals()
	refresh_modules()

## Setup service dependencies [br]
## [code]setup_services()[/code]
func setup_services() -> void:
	module_manager = ModuleManager.new()
	add_child(module_manager)
	
	git_service = GitService.new(module_manager)
	
	# Create HTTPRequest node for GitHub API calls
	http_request = HTTPRequest.new()
	add_child(http_request)
	
	module_operations = ModuleOperations.new(module_manager, git_service, http_request)
	dialog_manager = DialogManager.new(self)
	module_generator = ModuleGenerator.new()

## Setup UI components [br]
## [code]setup_components()[/code]
func setup_components() -> void:
	# Create status manager
	status_manager = StatusManager.new(status_label)
	
	# Create import workflow manager
	import_workflow_manager = ImportWorkflowManager.new(module_operations, status_manager)

## Setup the UI components [br]
## [code]setup_ui()[/code]
func setup_ui() -> void:
	# Set up button icons
	create_button.icon = EditorInterface.get_editor_theme().get_icon("Add", "EditorIcons")
	
	create_button.pressed.connect(_on_create_button_pressed)
	import_button.pressed.connect(_on_import_button_pressed)
	refresh_button.pressed.connect(_on_refresh_button_pressed)
	status_manager.set_ready()

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
	
	# Import workflow signals
	import_workflow_manager.import_completed.connect(_on_import_completed)
	
	# Git service signals
	git_service.git_settings_configured.connect(_on_git_settings_configured)
	git_service.repository_cloned.connect(_on_repository_cloned)
	git_service.workflow_completed.connect(_on_workflow_completed)
	git_service.git_settings_needed.connect(_on_git_settings_needed)
	git_service.repository_url_needed.connect(_on_repository_url_needed)
	
	# Module operations signals
	module_operations.module_imported.connect(_on_module_imported)
	module_operations.module_copied.connect(_on_module_copied)

## Refresh the list of available modules [br]
## [code]refresh_modules()[/code]
func refresh_modules() -> void:
	status_manager.set_refreshing()
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
		checkbox.toggled.connect(func(pressed): _on_module_toggled(module_id, pressed))
		checkbox.add_theme_font_size_override("font_size", 14)
		checkbox.tooltip_text = module_operations.wrap_tooltip_text(config.description)
		checkbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# Create git button
		var git_button = Button.new()
		git_button.icon = EditorInterface.get_editor_theme().get_icon("VcsBranches", "EditorIcons")
		git_button.tooltip_text = "Git Integration - Copy module to git folder and open in git client"
		git_button.size_flags_horizontal = Control.SIZE_SHRINK_END
		git_button.pressed.connect(func(): _on_git_integration_requested(module_id))
		# Add to horizontal container
		hbox.add_child(checkbox)
		hbox.add_child(git_button)
		# Add to module list
		module_list.add_child(hbox)

## Update the state of a specific checkbox taking [module_id] and [state] [br]
## [code]update_checkbox_state("jump_boost", true)[/code]
func update_checkbox_state(module_id: String, state: bool) -> void:
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

## Handle create button press [br]
## [code]_on_create_button_pressed()[/code]
func _on_create_button_pressed() -> void:
	dialog_manager.show_create_module_dialog()

## Handle import button press [br]
## [code]_on_import_button_pressed()[/code]
func _on_import_button_pressed() -> void:
	dialog_manager.show_import_dialog()

## Handle module checkbox toggle taking [module_id] and [enabled] [br]
## [code]_on_module_toggled("jump_boost", true)[/code]
func _on_module_toggled(module_id: String, enabled: bool) -> void:
	var available_modules = module_manager.get_available_modules()
	var module_name = available_modules[module_id].config.name
	
	if enabled:
		status_manager.set_module_enabling(module_name)
	else:
		status_manager.set_module_disabling(module_name)
	
	# Use the persistence system to handle module state
	if module_manager.set_module_enabled(module_id, enabled):
		if enabled:
			status_manager.set_module_enabled_success(module_name)
		else:
			status_manager.set_module_disabled_success(module_name)
	else:
		if enabled:
			status_manager.set_module_enable_failed(module_name)
		else:
			status_manager.set_module_disable_failed(module_name)
		# Revert checkbox state on failure
		update_checkbox_state(module_id, not enabled)

## Handle git integration request taking [module_id] [br]
## [code]_on_git_integration_requested("jump_boost")[/code]
func _on_git_integration_requested(module_id: String) -> void:
	status_manager.set_git_integration_starting(module_id)
	git_service.start_git_integration(module_id)

## Handle modules refreshed signal [br]
## [code]_on_modules_refreshed()[/code]
func _on_modules_refreshed() -> void:
	update_module_list()
	status_manager.set_refreshed()

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
	git_service.set_git_client_path(path)
	status_manager.set_git_client_configured(path)
	git_service.continue_after_git_client_configured()

## Handle module folder selection [br]
## [code]_on_module_folder_selected("C:/Dev/Modules")[/code]
func _on_module_folder_selected(path: String) -> void:
	git_service.set_default_module_folder(path)
	status_manager.set_module_folder_configured(path)
	git_service.continue_after_module_folder_configured()

## Handle git client dialog canceled [br]
## [code]_on_git_client_dialog_canceled()[/code]
func _on_git_client_dialog_canceled() -> void:
	status_manager.set_git_client_canceled()

## Handle module folder dialog canceled [br]
## [code]_on_module_folder_dialog_canceled()[/code]
func _on_module_folder_dialog_canceled() -> void:
	status_manager.set_module_folder_canceled()

## Handle repository URL confirmed [br]
## [code]_on_repository_url_confirmed()[/code]
func _on_repository_url_confirmed() -> void:
	var repository_url = dialog_manager.get_repository_url_input()
	
	if repository_url == "":
		status_manager.set_error("Repository URL cannot be empty")
		return
	
	status_manager.set_git_integration_setup()
	git_service.continue_with_repository_url(repository_url)

## Handle repository URL dialog canceled [br]
## [code]_on_repository_url_canceled()[/code]
func _on_repository_url_canceled() -> void:
	status_manager.set_git_integration_canceled()
	git_service.cancel_workflow()

## Handle import dialog confirmed [br]
## [code]_on_import_confirmed()[/code]
func _on_import_confirmed() -> void:
	var repository_url = dialog_manager.get_import_url_input()
	await import_workflow_manager.start_import(repository_url)

## Handle import dialog canceled [br]
## [code]_on_import_canceled()[/code]
func _on_import_canceled() -> void:
	status_manager.set_import_canceled()

## Handle create module dialog confirmed [br]
## [code]_on_create_module_confirmed()[/code]
func _on_create_module_confirmed() -> void:
	var module_data = dialog_manager.get_create_module_data()
	
	# Validate input
	if module_data.name.is_empty() or module_data.id.is_empty():
		status_manager.set_error("Module name and ID are required")
		return
	
	if module_data.author.is_empty():
		status_manager.set_error("Author name is required")
		return
	
	# Validate module ID format
	if not _is_valid_module_id(module_data.id):
		status_manager.set_error("Module ID must contain only lowercase letters, numbers, and underscores")
		return
	
	status_manager.set_status("Creating module '" + module_data.name + "'...")
	
	# Generate the module
	if module_generator.create_module(module_data.name, module_data.id, module_data.author, module_data.description):
		status_manager.set_status("Module '" + module_data.name + "' created successfully!")
		# Delay module refresh to allow Godot to process the new files
		await Engine.get_main_loop().create_timer(0.5).timeout
		refresh_modules()
	else:
		status_manager.set_error("Failed to create module")

## Handle create module dialog canceled [br]
## [code]_on_create_module_canceled()[/code]
func _on_create_module_canceled() -> void:
	status_manager.set_status("Module creation canceled")

## Handle import workflow completed taking [success] and [message] [br]
## [code]_on_import_completed(true, "Success message")[/code]
func _on_import_completed(success: bool, message: String) -> void:
	if success:
		refresh_modules()

## Handle git settings configured signal [br]
## [code]_on_git_settings_configured()[/code]
func _on_git_settings_configured() -> void:
	status_manager.set_git_settings_configured()

## Handle repository cloned signal taking [success] and [path] [br]
## [code]_on_repository_cloned(success, path)[/code]
func _on_repository_cloned(success: bool, path: String) -> void:
	status_manager.set_repository_cloned(success, path)

## Handle module imported signal taking [module_id] and [success] [br]
## [code]_on_module_imported("jump_boost", true)[/code]
func _on_module_imported(module_id: String, success: bool) -> void:
	status_manager.set_module_imported(success, module_id)
	if success:
		refresh_modules()

## Handle module copied signal taking [source_path], [dest_path] and [success] [br]
## [code]_on_module_copied("source", "dest", true)[/code]
func _on_module_copied(source_path: String, dest_path: String, success: bool) -> void:
	status_manager.set_module_copied(success, source_path, dest_path)

## Handle workflow completed signal taking [success] and [message] [br]
## [code]_on_workflow_completed(true, "Success message")[/code]
func _on_workflow_completed(success: bool, message: String) -> void:
	status_manager.set_workflow_completed(success, message)

## Handle git settings needed signal taking [setting_type] [br]
## [code]_on_git_settings_needed("git_client")[/code]
func _on_git_settings_needed(setting_type: String) -> void:
	status_manager.set_git_settings_needed(setting_type)
	if setting_type == "git_client":
		dialog_manager.show_git_client_dialog()
	elif setting_type == "module_folder":
		dialog_manager.show_module_folder_dialog()

## Handle repository URL needed signal taking [module_id] [br]
## [code]_on_repository_url_needed("jump_boost")[/code]
func _on_repository_url_needed(module_id: String) -> void:
	status_manager.set_repository_url_needed(module_id)
	dialog_manager.show_repository_url_dialog()

# =============================================================================
# HELPER METHODS
# =============================================================================

## Deferred git client opening taking [path] [br]
## [code]_open_git_client_deferred("C:/Dev/jump_boost")[/code]
func _open_git_client_deferred(path: String) -> void:
	if git_service.open_in_git_client(path):
		status_manager.set_git_client_opened(path)
	else:
		status_manager.set_git_client_open_failed()

## Validate module ID format taking [module_id] [br]
## [code]var valid = _is_valid_module_id("my_module")[/code]
func _is_valid_module_id(module_id: String) -> bool:
	if module_id.is_empty():
		return false
	
	# Check if it starts with a letter or underscore
	var first_char = module_id[0]
	if not (first_char.is_valid_identifier() or first_char == "_"):
		return false
	
	# Check all characters are valid (letters, numbers, underscores)
	for i in range(module_id.length()):
		var char = module_id[i]
		if not (char.is_valid_identifier() or char == "_"):
			return false
	
	# Check it's lowercase
	return module_id == module_id.to_lower()

 