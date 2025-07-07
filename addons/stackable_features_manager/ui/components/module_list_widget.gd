## Module list widget for displaying and managing stackable feature modules [br]
## Handles module checkboxes, git buttons, and state management in a reusable component
##
class_name ModuleListWidget
extends VBoxContainer

## Signals for module actions
signal module_toggled(module_id: String, enabled: bool)
signal git_integration_requested(module_id: String)

## UI references
var scroll_container: ScrollContainer
var module_list: VBoxContainer

## Service references
var module_manager: ModuleManager
var module_operations: ModuleOperations

## Initialize the module list widget [br]
## [code]_ready()[/code]
func _ready() -> void:
	setup_ui()

## Setup the UI structure [br]
## [code]setup_ui()[/code]
func setup_ui() -> void:
	scroll_container = ScrollContainer.new()
	scroll_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	
	module_list = VBoxContainer.new()
	scroll_container.add_child(module_list)
	add_child(scroll_container)

## Initialize with service dependencies taking [p_module_manager] and [p_module_operations] [br]
## [code]widget.initialize(module_manager, module_operations)[/code]
func initialize(p_module_manager: ModuleManager, p_module_operations: ModuleOperations) -> void:
	module_manager = p_module_manager
	module_operations = p_module_operations

## Update the module list display with checkboxes and git buttons [br]
## [code]widget.update_module_list()[/code]
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
## [code]widget.update_checkbox_state("jump_boost", true)[/code]
func update_checkbox_state(module_id: String, state: bool) -> void:
	var available_modules = module_manager.get_available_modules()
	var module_name = available_modules[module_id].config.name
	
	for child in module_list.get_children():
		if child is HBoxContainer:
			var checkbox = child.get_child(0)
			if checkbox is CheckBox and checkbox.text == module_name:
				checkbox.button_pressed = state
				break

## Handle module checkbox toggle taking [pressed] and [module_id] [br]
## [code]_on_module_toggled(true, "jump_boost")[/code]
func _on_module_toggled(pressed: bool, module_id: String) -> void:
	module_toggled.emit(module_id, pressed)

## Handle git button press for a module taking [module_id] [br]
## [code]_on_git_button_pressed("jump_boost")[/code]
func _on_git_button_pressed(module_id: String) -> void:
	git_integration_requested.emit(module_id) 