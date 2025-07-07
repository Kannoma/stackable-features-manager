## Service locator for managing dependencies in the stackable features manager [br]
## Provides centralized access to services without circular dependencies
##
class_name ServiceLocator
extends RefCounted

## Singleton instance
static var _instance: ServiceLocator

## Registered services
var _services: Dictionary = {}

## Get the singleton instance [br]
## [code]var locator = ServiceLocator.get_instance()[/code]
static func get_instance() -> ServiceLocator:
	if not _instance:
		_instance = ServiceLocator.new()
	return _instance

## Register a service taking [service_name] and [service_instance] [br]
## [code]ServiceLocator.get_instance().register("ModuleManager", manager)[/code]
func register(service_name: String, service_instance: Variant) -> void:
	_services[service_name] = service_instance

## Get a registered service taking [service_name] [br]
## [code]var manager = ServiceLocator.get_instance().get_service("ModuleManager")[/code]
func get_service(service_name: String) -> Variant:
	return _services.get(service_name, null)

## Check if a service is registered taking [service_name] [br]
## [code]if ServiceLocator.get_instance().has_service("ModuleManager"):[/code]
func has_service(service_name: String) -> bool:
	return service_name in _services

## Unregister a service taking [service_name] [br]
## [code]ServiceLocator.get_instance().unregister("ModuleManager")[/code]
func unregister(service_name: String) -> void:
	_services.erase(service_name)

## Clear all services [br]
## [code]ServiceLocator.get_instance().clear()[/code]
func clear() -> void:
	_services.clear() 