# Stackable Features Manager

Stackable Features Manager is a plugin for the Godot Engine that helps you organize your project into modular, reusable feature modules. It is designed for developers who want to build scalable, maintainable games by composing functionality from independent, self-contained modules.

---

## Project Overview

This plugin provides a framework for creating, integrating, and managing feature modules in Godot. Each module is isolated, making it easy to add, remove, or update features without impacting the rest of your project. The manager handles module discovery, lifecycle, and safe API access, so you can focus on building features, not boilerplate.

---

## Why Use Stackable Features Manager?

- **Modular by design:** Develop features as independent modules for easy reuse and sharing.
- **Rapid prototyping:** Add, remove, or swap features without breaking your project structure.
- **Safe API access:** Built-in checks for missing modules, disabled features, or absent API functions.
- **Git integration:** Built-in git integration for copying modules to development folders and managing repositories.
- **Plug-and-play:** Integrate modules into any Godot project with minimal setup.

---

## How It Works

Stackable Features Manager is built around a few core components:

- **Module Manager:** The central hub for loading, unloading, and managing the lifecycle of modules.
- **Manifest Loader:** Reads and validates module manifests, ensuring correct configuration and compatibility.
- **Module Registry:** Tracks all available modules and their enabled/disabled state.
- **API Wrappers:** Allow you to call module APIs safely, handling missing modules or functions gracefully.

The system checks if a module exists before loading or executing it, respects enabled/disabled states, and provides clear feedback if an API function is missing. This approach helps prevent runtime errors and makes your project more robust.

---

## Getting Started

1. **Installation:**
   - Copy the `stackable_features_manager` folder to your project's `addons/` directory.
   - Enable the plugin in Godot's Project Settings.
2. **Usage:**
   - Open the "Module Manager" dock in the Godot editor to manage your modules.
   - Use the git integration button next to each module to copy it to your development environment.
   - To use this framework, create your own feature modules and place them inside the `stackable_features/` directory in your project. The manager does not provide built-in modules; it is designed to help you organize and manage the modules you create for your own game or toolset.
3. **Git Integration:**
   - See [GIT_INTEGRATION.md](GIT_INTEGRATION.md) for detailed information about the git integration features.

---

## Typical Use Cases

- Prototyping new game features quickly.
- Scaling your game architecture with modular components.
- Building a library of reusable, shareable features for Godot projects.

---

## Requirements and Limitations

- **Requires Godot:** This plugin is designed to work within the Godot Engine environment.
- **No built-in features:** The manager is a framework for your own modules; it does not include pre-made game features.

---

## Support and Contact

A Discord community is coming soon. In the meantime, you can reach out via [email](mailto:matteo.r.simonetti@gmail.com) for support or collaboration.

---

## Support Me

If you find this project useful, you can support me on Ko-fi:

[![ko-fi](https://ko-fi.com/img/githubbutton_sm.svg)](https://ko-fi.com/kanno) 