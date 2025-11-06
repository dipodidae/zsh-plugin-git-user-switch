# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-11-06

### Added
- Initial release of git-user-switch plugin
- Main `gus` command to switch between GitHub users
- Automatic SSH config updates
- GitHub CLI authentication switching
- Automatic backup creation for SSH config
- Input validation and error handling
- Support for two users: dipodidae and spend-cloud-tom
- Plugin unload functionality
- Comprehensive test suite
- Documentation (README, QUICKSTART, EXAMPLES)
- Compliance with Zsh Plugin Standard
- Compliance with Google Shell Style Guide

### Features
- Switch between multiple GitHub accounts with a single command
- Automatically updates `~/.ssh/config` with correct SSH key
- Switches `gh` CLI authentication
- Creates backups before modifying SSH config
- Helpful error messages and validation
- Clean namespace management (uses `.` prefix for private functions)
- Standard plugin hash to prevent pollution
- Plugin manager compatibility

### Documentation
- Complete README.md with installation instructions
- QUICKSTART.md for fast setup
- EXAMPLES.md showing usage scenarios
- Example SSH config file
- MIT License
- Test suite for validation

## [Unreleased]

### Planned
- Support for additional users
- Configuration file for custom user/key mappings
- Better detection of SSH key types (ed25519, rsa, etc.)
- Optional git config switching (user.name, user.email)
- Completion support for username arguments
- Interactive mode for selecting users

---

[1.0.0]: https://github.com/dipodidae/zsh-plugin-git-user-switch/releases/tag/v1.0.0
