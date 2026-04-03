#!/usr/bin/env zsh
# Copy this file to ${XDG_CONFIG_HOME:-$HOME/.config}/git-user-switch/config.zsh

typeset -gA GUS_USERS
GUS_USERS=(
  "personal:key" "~/.ssh/personal"
  "personal:email" "personal@example.com"
  "personal:name" "Personal User"
  "personal:host_alias" "github-personal"
  "personal:gh_user" "personal-gh"

  "work:key" "~/.ssh/work"
  "work:email" "work@example.com"
  "work:name" "Work User"
  "work:host_alias" "github-work"
  "work:gh_user" "work-gh"
)

# Optional toggles. Set these in .zshrc before loading the plugin.
# export GUS_MODE=safe
# export GUS_AUTO_SWITCH=1
# export GUS_VERBOSE=0
# export GUS_ENABLE_GH_SWITCH=1
# export GUS_CONFIG_FILE="$HOME/.config/git-user-switch/config.zsh"

# Example safe-mode SSH aliases for ~/.ssh/config:
# Host github-personal
#   HostName github.com
#   User git
#   IdentityFile ~/.ssh/personal
#
# Host github-work
#   HostName github.com
#   User git
#   IdentityFile ~/.ssh/work
