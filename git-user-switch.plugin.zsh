#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et
#
# Git User Switch - A simple zsh plugin to switch between GitHub users
# Switches both SSH config and gh CLI authentication

# Standardized $0 handling for plugin location
0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

# Standard plugin hash to avoid namespace pollution
typeset -gA Plugins
Plugins[GIT_USER_SWITCH_DIR]="${0:h}"

# User-to-SSH-key mapping (configurable)
# Users can set this in their .zshrc BEFORE loading the plugin:
#   typeset -gA GUS_USER_KEYS
#   GUS_USER_KEYS=(
#     "myuser1" "~/.ssh/mykey1"
#     "myuser2" "~/.ssh/mykey2"
#   )
typeset -gA GUS_USER_KEYS

# Default configuration if not already set
if (( ${#GUS_USER_KEYS[@]} == 0 )); then
  GUS_USER_KEYS=(
    "dipodidae"       "~/.ssh/dipodidae"
    "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
  )
fi

# Email-to-username mapping for auto-switching (configurable)
# Users can set this in their .zshrc BEFORE loading the plugin:
#   typeset -gA GUS_EMAIL_TO_USER
#   GUS_EMAIL_TO_USER=(
#     "user1@example.com" "github-user1"
#     "user2@example.com" "github-user2"
#   )
typeset -gA GUS_EMAIL_TO_USER

# Default email mapping if not already set
if (( ${#GUS_EMAIL_TO_USER[@]} == 0 )); then
  GUS_EMAIL_TO_USER=(
    "dipodidae@users.noreply.github.com"       "dipodidae"
    "spend-cloud-tom@users.noreply.github.com" "spend-cloud-tom"
  )
fi

# Auto-switch configuration
typeset -g GUS_AUTO_SWITCH="${GUS_AUTO_SWITCH:-1}"  # Enable by default
typeset -g GUS_CURRENT_USER=""  # Track current user to avoid redundant switches

#######################################
# Print error message to STDERR
# Globals:
#   None
# Arguments:
#   Error message to print
# Outputs:
#   Writes error message to STDERR
#######################################
.gus_err() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  echo "[git-user-switch]: $*" >&2
}

#######################################
# Get the git user.email from current directory
# Globals:
#   None
# Arguments:
#   None
# Outputs:
#   Git user email to STDOUT
# Returns:
#   0 if in git repo, 1 otherwise
#######################################
.gus_get_git_email() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  local MATCH REPLY
  integer MBEGIN MEND
  local -a match mbegin mend reply

  # Check if we're in a git repository
  if ! git rev-parse --git-dir &>/dev/null; then
    return 1
  fi

  # Get the user.email from git config
  local email
  email="$(git config user.email 2>/dev/null)"

  if [[ -z "${email}" ]]; then
    return 1
  fi

  echo "${email}"
  return 0
}

#######################################
# Automatically switch user based on git config
# Called by chpwd hook when directory changes
# Globals:
#   GUS_AUTO_SWITCH
#   GUS_EMAIL_TO_USER
#   GUS_CURRENT_USER
# Arguments:
#   None
# Returns:
#   0 on success or no action needed, 1 on error
#######################################
→gus_auto_switch() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  local MATCH REPLY
  integer MBEGIN MEND
  local -a match mbegin mend reply

  # Skip if auto-switch is disabled
  if [[ "${GUS_AUTO_SWITCH}" != "1" ]]; then
    return 0
  fi

  # Get git email from current directory
  local git_email
  git_email="$(.gus_get_git_email)" || return 0

  # Look up corresponding GitHub username
  local github_user="${GUS_EMAIL_TO_USER[$git_email]}"

  # If no mapping found, return silently
  if [[ -z "${github_user}" ]]; then
    return 0
  fi

  # Skip if already on this user (avoid redundant switches)
  if [[ "${GUS_CURRENT_USER}" == "${github_user}" ]]; then
    return 0
  fi

  # Perform the switch silently
  echo "🔄 Auto-switching to GitHub user: ${github_user} (based on git config)"

  # Update SSH config
  .gus_update_ssh_config "${github_user}" || return 1

  # Switch gh authentication
  .gus_switch_gh_auth "${github_user}" || return 1

  # Update current user tracking
  GUS_CURRENT_USER="${github_user}"

  return 0
}

#######################################
# Update SSH config for GitHub with the specified user
# Globals:
#   HOME
#   GUS_USER_KEYS
# Arguments:
#   Username to switch to
# Returns:
#   0 on success, 1 on error
#######################################
.gus_update_ssh_config() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  local MATCH REPLY
  integer MBEGIN MEND
  local -a match mbegin mend reply

  local username="$1"
  local ssh_config="${HOME}/.ssh/config"
  local ssh_key_file

  # Get SSH key file from configuration
  ssh_key_file="${GUS_USER_KEYS[$username]}"

  if [[ -z "${ssh_key_file}" ]]; then
    .gus_err "No SSH key configured for user: ${username}"
    .gus_err "Available users: ${(k)GUS_USER_KEYS[*]}"
    return 1
  fi

  # Expand tilde in path
  ssh_key_file="${ssh_key_file/#\~/$HOME}"

  # Check if SSH config exists
  if [[ ! -f "${ssh_config}" ]]; then
    .gus_err "SSH config not found: ${ssh_config}"
    return 1
  fi

  # Check if SSH key exists
  if [[ ! -f "${ssh_key_file}" ]]; then
    .gus_err "SSH key not found: ${ssh_key_file}"
    .gus_err "Expected key at: ${ssh_key_file}"
    return 1
  fi

  # Create backup of SSH config
  cp "${ssh_config}" "${ssh_config}.bak" || {
    .gus_err "Failed to create backup of SSH config"
    return 1
  }

  # Update the IdentityFile line in the GitHub section
  # Using sed to find and replace the IdentityFile line after Host github.com
  if command -v gsed &>/dev/null; then
    local sed_cmd="gsed"
  else
    local sed_cmd="sed"
  fi

  # Use awk to update the GitHub section
  awk -v keyfile="${ssh_key_file}" '
    /^Host github\.com/ { in_github=1 }
    in_github && /^Host / && !/^Host github\.com/ { in_github=0 }
    in_github && /^[[:space:]]*IdentityFile/ {
      sub(/IdentityFile.*/, "IdentityFile " keyfile)
    }
    { print }
  ' "${ssh_config}" > "${ssh_config}.tmp" || {
    .gus_err "Failed to update SSH config"
    mv "${ssh_config}.bak" "${ssh_config}"
    return 1
  }

  mv "${ssh_config}.tmp" "${ssh_config}" || {
    .gus_err "Failed to write updated SSH config"
    mv "${ssh_config}.bak" "${ssh_config}"
    return 1
  }

  echo "✓ Updated SSH config to use: ${ssh_key_file}"
  return 0
}

#######################################
# Switch gh CLI authentication to specified user
# Globals:
#   None
# Arguments:
#   Username to switch to
# Returns:
#   0 on success, 1 on error
#######################################
.gus_switch_gh_auth() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  local MATCH REPLY
  integer MBEGIN MEND
  local -a match mbegin mend reply

  local username="$1"

  # Check if gh is installed
  if ! command -v gh &>/dev/null; then
    .gus_err "gh CLI not found. Please install it first."
    return 1
  fi

  # Switch gh authentication
  gh auth switch --user "${username}" || {
    .gus_err "Failed to switch gh authentication to ${username}"
    .gus_err "Make sure ${username} is authenticated with 'gh auth login'"
    return 1
  }

  echo "✓ Switched gh CLI to user: ${username}"
  return 0
}

#######################################
# Main function to switch git user
# Switches both SSH config and gh CLI authentication
# Globals:
#   GUS_USER_KEYS
# Arguments:
#   Username to switch to
# Outputs:
#   Success/error messages to STDOUT/STDERR
# Returns:
#   0 on success, 1 on error
#######################################
gus() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  local MATCH REPLY
  integer MBEGIN MEND
  local -a match mbegin mend reply

  local username="$1"

  # Get valid usernames from configuration
  local -a valid_users
  valid_users=( "${(k)GUS_USER_KEYS[@]}" )

  # Validate input
  if [[ -z "${username}" ]]; then
    .gus_err "Usage: gus <username>"
    .gus_err "Available users: ${valid_users[*]}"
    return 1
  fi

  # Check if username is valid
  if [[ -z "${GUS_USER_KEYS[$username]}" ]]; then
    .gus_err "Invalid username: ${username}"
    .gus_err "Available users: ${valid_users[*]}"
    return 1
  fi

  echo "Switching to GitHub user: ${username}"

  # Update SSH config
  .gus_update_ssh_config "${username}" || return 1

  # Switch gh authentication
  .gus_switch_gh_auth "${username}" || return 1

  # Update current user tracking
  GUS_CURRENT_USER="${username}"

  echo ""
  echo "✓ Successfully switched to ${username}"
  echo "  SSH key and gh CLI are now configured for this user."

  return 0
}

#######################################
# Unload function to clean up when plugin is unloaded
# Globals:
#   Plugins
#   GUS_USER_KEYS
#   GUS_EMAIL_TO_USER
#   GUS_AUTO_SWITCH
#   GUS_CURRENT_USER
# Arguments:
#   None
#######################################
git_user_switch_plugin_unload() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  # Remove chpwd hook
  if (( ${+functions[add-zsh-hook]} )); then
    add-zsh-hook -d chpwd →gus_auto_switch
  fi

  # Unset functions
  unfunction gus 2>/dev/null
  unfunction .gus_err 2>/dev/null
  unfunction .gus_get_git_email 2>/dev/null
  unfunction .gus_update_ssh_config 2>/dev/null
  unfunction .gus_switch_gh_auth 2>/dev/null
  unfunction →gus_auto_switch 2>/dev/null
  unfunction git_user_switch_plugin_unload 2>/dev/null

  # Clean up plugin data
  unset 'Plugins[GIT_USER_SWITCH_DIR]'
  unset GUS_CURRENT_USER

  # Clean up configuration (only if it was set by the plugin)
  # Users who set GUS_USER_KEYS manually should unset it themselves
}

# Register chpwd hook for auto-switching
autoload -Uz add-zsh-hook
add-zsh-hook chpwd →gus_auto_switch

# Run auto-switch on plugin load (for current directory)
→gus_auto_switch

# Register with plugin manager if available
if [[ -n "${zsh_loaded_plugins}" ]]; then
  zsh_loaded_plugins+=("${0:h:t}")
fi
