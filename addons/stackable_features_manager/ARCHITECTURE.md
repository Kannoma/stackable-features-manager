# Stackable Features Manager - Architecture

## Directory Structure

```
addons/stackable_features_manager/
├── core/                           # Core functionality
│   ├── api/                        # API safety wrappers
│   │   ├── safe_api_wrapper.gd     # Basic safe API wrapper
│   │   ├── null_safe_api.gd        # Null-safe operations
│   │   ├── universal_safe_api.gd   # Universal safe API
│   │   └── module_api.gd           # Module API interface
│   ├── loading/                    # Manifest and config loading
│   │   ├── manifest_loader.gd      # JSON manifest loader
│   │   └── manifest_manager.gd     # Manifest management
│   ├── operations/                 # Module operations
│   │   └── module_operations.gd    # Import, copy, git integration
│   ├── persistence/                # Data persistence
│   │   ├── feature_config.gd       # Feature configuration
│   │   ├── feature_module.gd       # Feature module data
│   │   └── module_config.gd        # Module configuration
│   ├── registry/                   # Module registry and management
│   │   ├── module_registry.gd      # Module registry
│   │   └── module_manager.gd       # Module lifecycle management
│   └── result.gd                   # Result pattern for error handling
├── services/                       # External service integrations
│   ├── git_service.gd              # Consolidated git operations
│   ├── http_service.gd             # HTTP and GitHub API
│   ├── module_service.gd           # Module file operations
│   └── dialog_manager.gd           # UI dialog management
├── ui/                            # User interface
│   ├── components/                 # Reusable UI components
│   │   ├── module_list_widget.gd   # Module list display
│   │   ├── status_manager.gd       # Status message handling
│   │   └── import_workflow_manager.gd # Import workflow coordination
│   ├── module_manager_dock.gd      # Main dock coordinator
│   └── module_manager_dock.tscn    # Main dock scene
├── plugin.cfg                     # Plugin configuration
├── stackable_features_manager.gd   # Main plugin script
└── README.md                       # Plugin documentation
```

## Design Patterns

### 1. Result Pattern
All operations that can fail return a `Result` object with consistent error handling:
```gdscript
var result = some_operation()
if result.is_error():
    print("Error: " + result.get_error())
else:
    var data = result.get_data()
```

### 2. Service Locator Pattern
Dependencies are resolved through a centralized service locator to eliminate circular dependencies:
```gdscript
var module_manager = ServiceLocator.get_service("ModuleManager")
```

### 3. Component-Based UI
Large UI classes are broken into focused components with single responsibilities:
- `ModuleListWidget` - Module display and interaction
- `StatusManager` - Status message handling
- `ImportWorkflowManager` - Import process coordination

### 4. Class Name Usage
All classes use proper `class_name` declarations instead of manual preloading:
```gdscript
class_name ModuleManager  # ✓ Good
const ModuleManager = preload("...") # ✗ Avoid
```

## Architecture Principles

### Single Responsibility
Each class has one clear purpose:
- `GitService` - All git operations
- `HttpService` - All HTTP/API operations  
- `ModuleOperations` - Module workflow coordination
- `StatusManager` - Status message handling

### Dependency Injection
Dependencies are injected rather than created internally:
```gdscript
func _init(module_manager: ModuleManager, git_service: GitService):
    self.module_manager = module_manager
    self.git_service = git_service
```

### Consistent Error Handling
All error-prone operations use the Result pattern with descriptive messages:
```gdscript
return Result.failure("Git operations failed: " + error_details)
return Result.success({"message": "Success", "data": result_data})
```

### Signal-Based Communication
Components communicate through signals rather than direct coupling:
```gdscript
signal module_toggled(module_id: String, enabled: bool)
signal git_integration_requested(module_id: String)
```

## Service Consolidation

### Git Services (Consolidated)
Previously scattered across 4 services, now unified in `GitService`:
- Repository cloning and management
- Git client integration
- Workflow state management
- Manifest repository updates

### API Safety (Preserved)
Three levels of API safety as requested:
- `SafeAPIWrapper` - Basic safety
- `NullSafeAPI` - Null-safe operations
- `UniversalSafeAPI` - Universal compatibility

## Configuration Management

### Autoload Registration
Proper autoload paths in `project.godot`:
```ini
[autoload]
ModuleRegistry="*res://addons/stackable_features_manager/core/registry/module_registry.gd"
```

### Class Name Resolution
All classes use `class_name` for automatic resolution:
```gdscript
var loader = ManifestLoader.new()  # Resolved by class_name
```

This architecture provides clear separation of concerns, eliminates circular dependencies, and maintains the requested API safety features while improving maintainability and testability. 