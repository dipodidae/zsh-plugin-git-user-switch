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
# Update SSH config for GitHub with the specified user
# Globals:
#   HOME
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

  # Determine SSH key file based on username
  case "${username}" in
    dipodidae)
      ssh_key_file="${HOME}/.ssh/id_rsa_dipodidae"
      ;;
    spend-cloud-tom)
      ssh_key_file="${HOME}/.ssh/id_rsa_spend_cloud_tom"
      ;;
    *)
      .gus_err "Unknown user: ${username}"
      return 1
      ;;
  esac

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
#   None
# Arguments:
#   Username to switch to (dipodidae or spend-cloud-tom)
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

  # Valid usernames
  local -a valid_users
  valid_users=(dipodidae spend-cloud-tom)

  # Validate input
  if [[ -z "${username}" ]]; then
    .gus_err "Usage: gus <username>"
    .gus_err "Valid usernames: ${valid_users[*]}"
    return 1
  fi

  # Check if username is valid
  if [[ ! " ${valid_users[*]} " =~ " ${username} " ]]; then
    .gus_err "Invalid username: ${username}"
    .gus_err "Valid usernames: ${valid_users[*]}"
    return 1
  fi

  echo "Switching to GitHub user: ${username}"

  # Update SSH config
  .gus_update_ssh_config "${username}" || return 1

  # Switch gh authentication
  .gus_switch_gh_auth "${username}" || return 1

  echo ""
  echo "✓ Successfully switched to ${username}"
  echo "  SSH key and gh CLI are now configured for this user."

  return 0
}

#######################################
# Unload function to clean up when plugin is unloaded
# Globals:
#   Plugins
# Arguments:
#   None
#######################################
git_user_switch_plugin_unload() {
  builtin emulate -L zsh ${=${options[xtrace]:#off}:+-o xtrace}
  builtin setopt extended_glob warn_create_global typeset_silent \
    no_short_loops rc_quotes no_auto_pushd

  # Unset functions
  unfunction gus 2>/dev/null
  unfunction .gus_err 2>/dev/null
  unfunction .gus_update_ssh_config 2>/dev/null
  unfunction .gus_switch_gh_auth 2>/dev/null
  unfunction git_user_switch_plugin_unload 2>/dev/null

  # Clean up plugin data
  unset 'Plugins[GIT_USER_SWITCH_DIR]'
}

# Register with plugin manager if available
if [[ -n "${zsh_loaded_plugins}" ]]; then
  zsh_loaded_plugins+=("${0:h:t}")
fi
