## Module: {MODULE_CLASS}
## Purpose: {MODULE_NAME} feature implementation
## Dependencies: FeatureModule, {CONFIG_CLASS}
##

# Core module implementation

@tool
extends FeatureModule

## Module state
var config: {CONFIG_CLASS}
var _api: {API_CLASS}
# var _player: CharacterBody3D

# =============================================================================
# MODULE LIFECYCLE
# =============================================================================

## Initializes module with provided configuration
func init(module_config: ModuleConfig) -> void:
	if module_config is {CONFIG_CLASS}:
		config = module_config as {CONFIG_CLASS}
	else:
		config = {CONFIG_CLASS}.new()
		config = config.get_default_config() as {CONFIG_CLASS}

## Activates module functionality
func ready() -> void:
	_api = {API_CLASS}.new(self)
	# Implement module initialization here
	pass

## Deactivates module and cleanup resources
func shutdown() -> void:
	# Implement cleanup logic here
	pass

# =============================================================================
# REQUIRED INTERFACE
# =============================================================================

func get_module_name() -> String:
	return "{MODULE_ID}"

func get_api() -> ModuleAPI:
	return _api

## Loads default configuration from resources
func load_default_config() -> void:
	var module_path = get_script().resource_path.get_base_dir()
	var default_config = FeatureConfig.load_module_resource(
		module_path + "/config_default.tres",
		module_path + "/config.gd"
	)
	
	if default_config:
		config = default_config
	else:
		config = {CONFIG_CLASS}.new()

# =============================================================================
# IMPLEMENTATION AREA
# =============================================================================

## Locates player node in scene tree
# func _find_player() -> void:
# 	_player = get_tree().get_first_node_in_group("player")

## Connects to relevant game signals
# func _connect_signals() -> void:
# 	if _player and _player.has_signal("jumped"):
# 		_player.jumped.connect(_on_player_jumped)

## Applies module effects to game state
# func _apply_boost() -> void:
# 	if _player and config.enabled:
# 		_player.jump_velocity *= config.multiplier

## Handles player events
# func _on_player_jumped() -> void:
# 	print("{MODULE_NAME}: Player jumped!")

# =============================================================================
# LIFECYCLE FLOW
# =============================================================================
# Module activation sequence:
# Game start -> init() -> ready() -> [module active]
# Module deactivation: shutdown() -> [module inactive]
# Configuration change: init() -> ready() -> [module reactivated]

# =============================================================================
# IMPLEMENTATION GUIDELINES
# =============================================================================
# ready() function:
# - Initialize API interface
# - Locate required scene nodes
# - Connect to game signals
# - Apply initial configuration
#
# shutdown() function:
# - Restore modified game state
# - Disconnect signal handlers
# - Clean up resources

# =============================================================================
# FEATURE MODULE FRAMEWORK
# =============================================================================
# FeatureModule base class provides:
# - Automatic module registration with system
# - Configuration persistence and loading
# - Standardized module interface
# - Error handling and safety checks
#
# Benefits of extending FeatureModule:
# - Automatic UI integration
# - Preset system compatibility
# - Inter-module communication
# - Consistent lifecycle management 