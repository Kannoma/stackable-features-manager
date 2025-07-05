# Git Integration Guide

The Stackable Features Manager plugin includes built-in git integration to help you quickly copy modules to your development environment and manage them with git.

---

## What Does It Do?
- Adds a git button next to each module in the Module Manager dock
- Copies modules to your chosen development folder
- Initializes a git repository or connects to an existing one
- Opens the module in your preferred git client

---

## Quick Setup
1. **First Use:**
   - Click the git button next to any module
   - Select your git client executable (e.g., Git Bash, SourceTree, GitKraken)
   - Choose your default module folder (where modules will be copied)
   - These settings are saved for future use

2. **Module Repository:**
   - To link a module to a remote repository, add a `repository` field to its `manifest.json`:
     ```json
     {
       "repository": "https://github.com/yourusername/my-module.git"
     }
     ```

---

## Workflow
1. Click the 🌿 button for a module
2. The module is copied to your development folder
3. If a repository is specified, it is set as the remote origin
4. If not, a new git repo is initialized
5. Your git client opens the module folder

---

## Supported Git Clients
- Git Bash / Git GUI
- SourceTree
- GitKraken
- Any client that can open a folder/project from the command line

---

## Troubleshooting
- **Git client not found:**
  - Check the path in Godot editor settings (`stackable_features/git_client_path`)
- **Module copy failed:**
  - Ensure the destination folder exists and is writable
- **Git operations failed:**
  - Make sure git is installed and accessible
  - Verify the repository URL (if used)

---

## Settings Location
- Git integration settings are stored in Godot's editor settings:
  - `stackable_features/git_client_path`
  - `stackable_features/default_module_folder`

You can change these at any time via the editor settings.

---

For more details, see the main [Stackable Features Manager README](README.md). 