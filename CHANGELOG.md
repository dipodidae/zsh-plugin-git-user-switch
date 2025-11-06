# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- **🔄 Auto-switching based on git config** - Plugin now automatically switches users when you `cd` into a directory based on `git config user.email`
- `GUS_EMAIL_TO_USER` configuration hash to map git emails to GitHub usernames
- `GUS_AUTO_SWITCH` option to enable/disable auto-switching (enabled by default)
- `→gus_auto_switch()` hook function triggered on directory changes via `chpwd`
- `.gus_get_git_email()` function to extract email from git config
- `GUS_CURRENT_USER` tracking to avoid redundant switches
- Configurable user-to-SSH-key mapping via `GUS_USER_KEYS` global hash
- Support for dynamic user configuration in `.zshrc`
- Configuration examples in `config.example.zsh`
- Comprehensive configuration guide in `CONFIGURATION.md`
- Test suite for configuration in `test-config.zsh`
- Auto-loading of `add-zsh-hook` for chpwd hook management

### Changed
- User list is now dynamically generated from `GUS_USER_KEYS`
- SSH key paths are now configurable instead of hardcoded
- Default configuration matches repository author's setup (can be overridden)
- Updated README with auto-switching documentation and examples
- Updated QUICKSTART with auto-switching setup guide
- Improved error messages to show available configured users
- Function naming now follows Zsh Plugin Standard (→ prefix for hooks, . prefix for private)
- Plugin now runs auto-switch on load (for current directory)

### Fixed
- Tilde expansion in SSH key paths now works correctly
- Default key paths now match repository author's setup
- Plugin unload function now properly removes chpwd hook
- Prevented redundant switches when already on correct user

## [0.1.0] - 2025-11-06

### Added
- Initial release of git-user-switch plugin
- Main `gus` command to switch between GitHub users
- Automatic SSH config updates via `.gus_update_ssh_config()`
- GitHub CLI authentication switching via `.gus_switch_gh_auth()`
- Automatic backup creation for SSH config
- Input validation and error handling via `.gus_err()`
- Support for two users: dipodidae and spend-cloud-tom
- Plugin unload functionality via `git_user_switch_plugin_unload()`
- Comprehensive test suite in `test.zsh`
- Documentation (README, QUICKSTART, EXAMPLES)
- Compliance with Zsh Plugin Standard
- Compliance with Google Shell Style Guide

### Features
- Switch between multiple GitHub accounts with a single command
- Automatically updates `~/.ssh/config` with correct SSH key using awk
- Switches `gh` CLI authentication
- Creates backups before modifying SSH config (`.bak` files)
- Helpful error messages and validation
- Clean namespace management (uses `.` prefix for private functions)
- Standard plugin hash (`Plugins[GIT_USER_SWITCH_DIR]`) to prevent pollution
- Plugin manager compatibility via `zsh_loaded_plugins` array
- Standardized $0 handling for plugin location detection
- Uses recommended shell options (extended_glob, warn_create_global, etc.)

### Documentation
- Complete README.md with installation instructions
- QUICKSTART.md for fast setup
- EXAMPLES.md showing usage scenarios
- Example SSH config file (ssh-config.example)
- MIT License
- Test suite for validation

---

## Future Ideas

### Planned Features
- Completion support for username arguments (zsh completions)
- Optional git config switching (user.name, user.email) per repository
- Better detection of SSH key types (ed25519, rsa, ecdsa, etc.)
- Interactive mode for selecting users (fzf integration?)
- Status command to show current user (`gus status`)
- List command to show all configured users (`gus list`)
- Dry-run mode to preview changes without applying them

---

[Unreleased]: https://github.com/dipodidae/zsh-plugin-git-user-switch/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/dipodidae/zsh-plugin-git-user-switch/releases/tag/v0.1.0
