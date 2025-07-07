## Dialog manager for UI dialog creation and management [br]
## Handles creation, configuration, and lifecycle of all dialogs in the module manager
##
class_name DialogManager
extends RefCounted

## Dialog references
var git_client_dialog: FileDialog
var module_folder_dialog: FileDialog
var repository_url_dialog: AcceptDialog
var import_dialog: AcceptDialog
var create_module_dialog: AcceptDialog

## Input references
var repository_url_input: LineEdit
var import_url_input: LineEdit
var module_name_input: LineEdit
var module_id_input: LineEdit
var module_author_input: LineEdit
var module_description_input: TextEdit

## Parent node for adding dialogs
var parent_node: Node

## Initialize dialog manager with parent node taking [parent] [br]
## [code]var dialog_manager = DialogManager.new(self)[/code]
func _init(parent: Node) -> void:
	parent_node = parent

## Create all dialogs [br]
## [code]dialog_manager.create_all_dialogs()[/code]
func create_all_dialogs() -> void:
	create_git_client_dialog()
	create_module_folder_dialog()
	create_repository_url_dialog()
	create_import_dialog()
	create_create_module_dialog()

## Create git client selection dialog [br]
## [code]dialog_manager.create_git_client_dialog()[/code]
func create_git_client_dialog() -> void:
	git_client_dialog = FileDialog.new()
	git_client_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	git_client_dialog.access = FileDialog.ACCESS_FILESYSTEM
	git_client_dialog.title = "Select Git Client Executable"
	git_client_dialog.add_filter("*.exe", "Executable Files")
	parent_node.add_child(git_client_dialog)

## Create module folder selection dialog [br]
## [code]dialog_manager.create_module_folder_dialog()[/code]
func create_module_folder_dialog() -> void:
	module_folder_dialog = FileDialog.new()
	module_folder_dialog.file_mode = FileDialog.FILE_MODE_OPEN_DIR
	module_folder_dialog.access = FileDialog.ACCESS_FILESYSTEM
	module_folder_dialog.title = "Select Default Module Folder"
	parent_node.add_child(module_folder_dialog)

## Create repository URL input dialog [br]
## [code]dialog_manager.create_repository_url_dialog()[/code]
func create_repository_url_dialog() -> void:
	repository_url_dialog = AcceptDialog.new()
	repository_url_dialog.title = "Add Repository URL"
	repository_url_dialog.ok_button_text = "Add Repository"
	
	# Create dialog content
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Enter the repository URL for this module:"
	vbox.add_child(label)
	
	repository_url_input = LineEdit.new()
	repository_url_input.placeholder_text = "https://github.com/username/repository.git"
	repository_url_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(repository_url_input)
	
	var example_label = Label.new()
	example_label.text = "Example: https://github.com/username/my-module.git"
	example_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(example_label)
	
	repository_url_dialog.add_child(vbox)
	parent_node.add_child(repository_url_dialog)

## Create import module dialog [br]
## [code]dialog_manager.create_import_dialog()[/code]
func create_import_dialog() -> void:
	import_dialog = AcceptDialog.new()
	import_dialog.title = "Import Module from GitHub"
	import_dialog.ok_button_text = "Import Module"
	
	# Create dialog content
	var vbox = VBoxContainer.new()
	
	var label = Label.new()
	label.text = "Enter the GitHub repository URL:"
	vbox.add_child(label)
	
	import_url_input = LineEdit.new()
	import_url_input.placeholder_text = "https://github.com/Kannoma/stackable-jump-boost"
	import_url_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(import_url_input)
	
	var example_label = Label.new()
	example_label.text = "Example: https://github.com/Kannoma/stackable-jump-boost"
	example_label.add_theme_font_size_override("font_size", 10)
	vbox.add_child(example_label)
	
	var info_label = Label.new()
	info_label.text = "The repository must contain a valid manifest.json file to be imported."
	info_label.add_theme_font_size_override("font_size", 10)
	info_label.modulate = Color.GRAY
	vbox.add_child(info_label)
	
	import_dialog.add_child(vbox)
	parent_node.add_child(import_dialog)

## Create create module dialog [br]
## [code]dialog_manager.create_create_module_dialog()[/code]
func create_create_module_dialog() -> void:
	create_module_dialog = AcceptDialog.new()
	create_module_dialog.title = "Create New Module"
	create_module_dialog.ok_button_text = "Create Module"
	create_module_dialog.size = Vector2i(500, 400)
	
	# Create dialog content
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 8)
	
	# Module name
	var name_label = Label.new()
	name_label.text = "Module Name:"
	vbox.add_child(name_label)
	
	module_name_input = LineEdit.new()
	module_name_input.placeholder_text = "My Awesome Feature"
	module_name_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(module_name_input)
	
	# Module ID
	var id_label = Label.new()
	id_label.text = "Module ID (lowercase, underscores only):"
	vbox.add_child(id_label)
	
	module_id_input = LineEdit.new()
	module_id_input.placeholder_text = "my_awesome_feature"
	module_id_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(module_id_input)
	
	# Auto-generate ID from name
	module_name_input.text_changed.connect(_on_module_name_changed)
	
	# Author
	var author_label = Label.new()
	author_label.text = "Author:"
	vbox.add_child(author_label)
	
	module_author_input = LineEdit.new()
	module_author_input.placeholder_text = "Your Name"
	module_author_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(module_author_input)
	
	# Description
	var desc_label = Label.new()
	desc_label.text = "Description:"
	vbox.add_child(desc_label)
	
	module_description_input = TextEdit.new()
	module_description_input.placeholder_text = "Brief description of what this module does..."
	module_description_input.custom_minimum_size = Vector2(0, 80)
	module_description_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_child(module_description_input)
	
	create_module_dialog.add_child(vbox)
	parent_node.add_child(create_module_dialog)

## Auto-generate module ID from name taking [text] [br]
## [code]_on_module_name_changed("My Feature")[/code]
func _on_module_name_changed(text: String) -> void:
	if module_id_input:
		var id = text.to_lower().replace(" ", "_").replace("-", "_")
		# Remove special characters
		var clean_id = ""
		for char in id:
			if char.is_valid_identifier() or char == "_":
				clean_id += char
		module_id_input.text = clean_id

## Show git client selection dialog [br]
## [code]dialog_manager.show_git_client_dialog()[/code]
func show_git_client_dialog() -> void:
	hide_all_dialogs()
	git_client_dialog.popup_centered(Vector2i(800, 600))

## Show module folder selection dialog [br]
## [code]dialog_manager.show_module_folder_dialog()[/code]
func show_module_folder_dialog() -> void:
	hide_all_dialogs()
	module_folder_dialog.popup_centered(Vector2i(800, 600))

## Show repository URL input dialog [br]
## [code]dialog_manager.show_repository_url_dialog()[/code]
func show_repository_url_dialog() -> void:
	repository_url_input.text = ""
	repository_url_dialog.popup_centered(Vector2i(600, 200))

## Show import module dialog [br]
## [code]dialog_manager.show_import_dialog()[/code]
func show_import_dialog() -> void:
	import_url_input.text = ""
	import_dialog.popup_centered(Vector2i(600, 250))

## Show create module dialog [br]
## [code]dialog_manager.show_create_module_dialog()[/code]
func show_create_module_dialog() -> void:
	module_name_input.text = ""
	module_id_input.text = ""
	module_author_input.text = ""
	module_description_input.text = ""
	create_module_dialog.popup_centered(Vector2i(500, 400))

## Hide all dialogs [br]
## [code]dialog_manager.hide_all_dialogs()[/code]
func hide_all_dialogs() -> void:
	if git_client_dialog and git_client_dialog.visible:
		git_client_dialog.hide()
	if module_folder_dialog and module_folder_dialog.visible:
		module_folder_dialog.hide()
	if repository_url_dialog and repository_url_dialog.visible:
		repository_url_dialog.hide()
	if import_dialog and import_dialog.visible:
		import_dialog.hide()
	if create_module_dialog and create_module_dialog.visible:
		create_module_dialog.hide()

## Connect dialog signals to handler functions [br]
## [code]dialog_manager.connect_signals(handler_object)[/code]
func connect_signals(handler: Object) -> void:
	# Git client dialog signals
	if not git_client_dialog.file_selected.is_connected(handler._on_git_client_selected):
		git_client_dialog.file_selected.connect(handler._on_git_client_selected)
	if not git_client_dialog.canceled.is_connected(handler._on_git_client_dialog_canceled):
		git_client_dialog.canceled.connect(handler._on_git_client_dialog_canceled)
	
	# Module folder dialog signals
	if not module_folder_dialog.dir_selected.is_connected(handler._on_module_folder_selected):
		module_folder_dialog.dir_selected.connect(handler._on_module_folder_selected)
	if not module_folder_dialog.canceled.is_connected(handler._on_module_folder_dialog_canceled):
		module_folder_dialog.canceled.connect(handler._on_module_folder_dialog_canceled)
	
	# Repository URL dialog signals
	if not repository_url_dialog.confirmed.is_connected(handler._on_repository_url_confirmed):
		repository_url_dialog.confirmed.connect(handler._on_repository_url_confirmed)
	if not repository_url_dialog.canceled.is_connected(handler._on_repository_url_canceled):
		repository_url_dialog.canceled.connect(handler._on_repository_url_canceled)
	
	# Import dialog signals
	if not import_dialog.confirmed.is_connected(handler._on_import_confirmed):
		import_dialog.confirmed.connect(handler._on_import_confirmed)
	if not import_dialog.canceled.is_connected(handler._on_import_canceled):
		import_dialog.canceled.connect(handler._on_import_canceled)
	
	# Create module dialog signals
	if not create_module_dialog.confirmed.is_connected(handler._on_create_module_confirmed):
		create_module_dialog.confirmed.connect(handler._on_create_module_confirmed)
	if not create_module_dialog.canceled.is_connected(handler._on_create_module_canceled):
		create_module_dialog.canceled.connect(handler._on_create_module_canceled)

## Get repository URL input text [br]
## [code]var url = dialog_manager.get_repository_url_input()[/code]
func get_repository_url_input() -> String:
	return repository_url_input.text.strip_edges()

## Get import URL input text [br]
## [code]var url = dialog_manager.get_import_url_input()[/code]
func get_import_url_input() -> String:
	return import_url_input.text.strip_edges()

## Get create module input data [br]
## [code]var data = dialog_manager.get_create_module_data()[/code]
func get_create_module_data() -> Dictionary:
	return {
		"name": module_name_input.text.strip_edges(),
		"id": module_id_input.text.strip_edges(),
		"author": module_author_input.text.strip_edges(),
		"description": module_description_input.text.strip_edges()
	}

## Check if any dialog is currently visible [br]
## [code]if dialog_manager.is_any_dialog_visible():[/code]
func is_any_dialog_visible() -> bool:
	return (git_client_dialog and git_client_dialog.visible) or \
		   (module_folder_dialog and module_folder_dialog.visible) or \
		   (repository_url_dialog and repository_url_dialog.visible) or \
		   (import_dialog and import_dialog.visible) or \
		   (create_module_dialog and create_module_dialog.visible) 