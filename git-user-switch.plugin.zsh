#!/usr/bin/env zsh
# -*- mode: zsh; sh-indentation: 2; indent-tabs-mode: nil; sh-basic-offset: 2; -*-
# vim: ft=zsh sw=2 ts=2 et

0="${ZERO:-${${0:#$ZSH_ARGZERO}:-${(%):-%N}}}"
0="${${(M)0:#/*}:-$PWD/$0}"

typeset -gA Plugins
Plugins[GIT_USER_SWITCH_DIR]="${0:h}"

typeset -gA GUS_USERS
typeset -g GUS_AUTO_SWITCH="${GUS_AUTO_SWITCH:-1}"
typeset -g GUS_VERBOSE="${GUS_VERBOSE:-0}"
typeset -g GUS_MODE="${GUS_MODE:-safe}"
typeset -g GUS_ENABLE_GH_SWITCH="${GUS_ENABLE_GH_SWITCH:-1}"
typeset -g GUS_CONFIG_FILE="${GUS_CONFIG_FILE:-${XDG_CONFIG_HOME:-${HOME}/.config}/git-user-switch/config.zsh}"
typeset -g GUS_STATE_DIR="${GUS_STATE_DIR:-${XDG_STATE_HOME:-${HOME}/.local/state}/git-user-switch}"
typeset -g GUS_LAST_USER_FILE="${GUS_LAST_USER_FILE:-${GUS_STATE_DIR}/last-user}"
typeset -g GUS_AUTO_SWITCH_LOCK_FILE="${GUS_AUTO_SWITCH_LOCK_FILE:-${GUS_STATE_DIR}/auto-switch.lock}"
typeset -g GUS_CONFIG_SOURCE=""
typeset -g GUS_LAST_ERROR=""

_gus_err() {
  emulate -L zsh -o extended_glob -o warn_create_global -o typeset_silent \
    -o no_short_loops -o rc_quotes -o no_auto_pushd

  GUS_LAST_ERROR="$*"
  print -u2 -- "[git-user-switch] $*"
}

_gus_info() {
  emulate -L zsh

  if [[ "${GUS_VERBOSE}" == "1" ]]; then
    print -- "$*"
  fi
}

_gus_notice() {
  emulate -L zsh

  if [[ -o interactive ]] && (( ${+functions[zle]} )); then
    zle -M -- "$*" 2>/dev/null || true
    return 0
  fi

  _gus_info "$*"
}

_gus_state_mkdir() {
  emulate -L zsh

  mkdir -p -- "${GUS_STATE_DIR}" || {
    _gus_err "Failed to create state directory: ${GUS_STATE_DIR}"
    return 1
  }
}

_gus_expand_path() {
  emulate -L zsh

  local path="$1"
  print -- "${path/#\~/${HOME}}"
}

_gus_collect_users() {
  emulate -L zsh -o extended_glob

  local result_name="$1"
  local key user
  local -a collected_users
  local -A seen

  for key in ${(k)GUS_USERS}; do
    if [[ "${key}" == *:key ]]; then
      user="${key%:key}"
      if [[ -z "${seen[$user]}" ]]; then
        seen[$user]=1
        collected_users+=("${user}")
      fi
    fi
  done

  eval "${result_name}=(\"\${collected_users[@]}\")"
}

_gus_user_field() {
  emulate -L zsh

  local user="$1"
  local field="$2"
  print -- "${GUS_USERS[${user}:${field}]}"
}

_gus_set_user_field_if_empty() {
  emulate -L zsh

  local user="$1"
  local field="$2"
  local value="$3"

  if [[ -z "${GUS_USERS[${user}:${field}]}" && -n "${value}" ]]; then
    GUS_USERS[${user}:${field}]="${value}"
  fi
}

_gus_default_config() {
  emulate -L zsh

  if (( ${#GUS_USERS[@]} > 0 )); then
    return 0
  fi

  GUS_USERS=(
    "dipodidae:key" "~/.ssh/dipodidae"
    "dipodidae:email" "dipodidae@users.noreply.github.com"
    "dipodidae:name" "dipodidae"
    "dipodidae:host_alias" "github-dipodidae"
    "dipodidae:gh_user" "dipodidae"
    "spend-cloud-tom:key" "~/.ssh/spend-cloud-tom"
    "spend-cloud-tom:email" "spend-cloud-tom@users.noreply.github.com"
    "spend-cloud-tom:name" "Tom"
    "spend-cloud-tom:host_alias" "github-spend-cloud-tom"
    "spend-cloud-tom:gh_user" "spend-cloud-tom"
  )
  GUS_CONFIG_SOURCE="defaults"
}

_gus_import_legacy_config() {
  emulate -L zsh -o extended_glob

  local user email name key
  local -A seen

  if (( ${#GUS_USERS[@]} > 0 )); then
    return 0
  fi

  if (( ${#GUS_USER_KEYS[@]} == 0 && ${#GUS_USER_EMAILS[@]} == 0 && ${#GUS_USER_NAMES[@]} == 0 && ${#GUS_EMAIL_TO_USER[@]} == 0 )); then
    return 1
  fi

  for user key in ${(kv)GUS_USER_KEYS}; do
    seen[$user]=1
    GUS_USERS[${user}:key]="${key}"
  done

  for user email in ${(kv)GUS_USER_EMAILS}; do
    seen[$user]=1
    GUS_USERS[${user}:email]="${email}"
  done

  for user name in ${(kv)GUS_USER_NAMES}; do
    seen[$user]=1
    GUS_USERS[${user}:name]="${name}"
  done

  for email user in ${(kv)GUS_EMAIL_TO_USER}; do
    seen[$user]=1
    GUS_USERS[${user}:email]="${GUS_USERS[${user}:email]:-${email}}"
  done

  for user in ${(k)seen}; do
    _gus_set_user_field_if_empty "${user}" name "${user}"
    _gus_set_user_field_if_empty "${user}" host_alias "github-${user}"
    _gus_set_user_field_if_empty "${user}" gh_user "${user}"
  done

  GUS_CONFIG_SOURCE="legacy"
  return 0
}

_gus_load_config_file() {
  emulate -L zsh

  if [[ ! -f "${GUS_CONFIG_FILE}" ]]; then
    return 1
  fi

  builtin source "${GUS_CONFIG_FILE}" || {
    _gus_err "Failed to load config file: ${GUS_CONFIG_FILE}"
    return 1
  }

  GUS_CONFIG_SOURCE="${GUS_CONFIG_FILE}"
  return 0
}

_gus_validate_config() {
  emulate -L zsh -o extended_glob

  local user key email alias gh_user
  local -a users
  local -A emails aliases gh_users

  _gus_collect_users users
  if (( ${#users[@]} == 0 )); then
    _gus_err "No users configured. Set GUS_USERS in ${GUS_CONFIG_FILE} or export legacy mappings before loading the plugin."
    return 1
  fi

  for user in "${users[@]}"; do
    key="$(_gus_user_field "${user}" key)"
    email="$(_gus_user_field "${user}" email)"
    alias="$(_gus_user_field "${user}" host_alias)"
    gh_user="$(_gus_user_field "${user}" gh_user)"

    if [[ -z "${key}" ]]; then
      _gus_err "Missing key for configured user: ${user}"
      return 1
    fi

    if [[ -z "${email}" ]]; then
      _gus_err "Missing email for configured user: ${user}"
      return 1
    fi

    if [[ -z "${alias}" ]]; then
      _gus_err "Missing host_alias for configured user: ${user}"
      return 1
    fi

    if [[ -n "${emails[$email]}" && "${emails[$email]}" != "${user}" ]]; then
      _gus_err "Duplicate email mapping: ${email} is assigned to both ${emails[$email]} and ${user}"
      return 1
    fi

    if [[ -n "${aliases[$alias]}" && "${aliases[$alias]}" != "${user}" ]]; then
      _gus_err "Duplicate host_alias mapping: ${alias} is assigned to both ${aliases[$alias]} and ${user}"
      return 1
    fi

    emails[$email]="${user}"
    aliases[$alias]="${user}"

    if [[ -n "${gh_user}" ]]; then
      if [[ -n "${gh_users[$gh_user]}" && "${gh_users[$gh_user]}" != "${user}" ]]; then
        _gus_err "Duplicate gh_user mapping: ${gh_user} is assigned to both ${gh_users[$gh_user]} and ${user}"
        return 1
      fi
      gh_users[$gh_user]="${user}"
    fi

    _gus_set_user_field_if_empty "${user}" name "${user}"
    _gus_set_user_field_if_empty "${user}" gh_user "${user}"
  done

  return 0
}

_gus_init() {
  emulate -L zsh

  if ! _gus_load_config_file; then
    _gus_import_legacy_config || _gus_default_config
  fi

  _gus_validate_config || return 1
}

_gus_user_exists() {
  emulate -L zsh

  [[ -n "${GUS_USERS[$1:key]}" ]]
}

_gus_user_for_email() {
  emulate -L zsh

  local email="$1"
  local user
  local -a users

  _gus_collect_users users
  for user in "${users[@]}"; do
    if [[ "$(_gus_user_field "${user}" email)" == "${email}" ]]; then
      print -- "${user}"
      return 0
    fi
  done

  return 1
}

_gus_user_for_alias() {
  emulate -L zsh

  local alias="$1"
  local user
  local -a users

  _gus_collect_users users
  for user in "${users[@]}"; do
    if [[ "$(_gus_user_field "${user}" host_alias)" == "${alias}" ]]; then
      print -- "${user}"
      return 0
    fi
  done

  return 1
}

_gus_in_git_repo() {
  emulate -L zsh

  git rev-parse --git-dir &>/dev/null
}

_gus_repo_root() {
  emulate -L zsh

  git rev-parse --show-toplevel 2>/dev/null
}

_gus_git_config_get() {
  emulate -L zsh

  git config --local --get "$1" 2>/dev/null
}

_gus_git_email() {
  emulate -L zsh

  _gus_git_config_get user.email
}

_gus_git_name() {
  emulate -L zsh

  _gus_git_config_get user.name
}

_gus_remote_names() {
  emulate -L zsh

  git remote 2>/dev/null
}

_gus_parse_remote_host() {
  emulate -L zsh

  local remote_url="$1"
  if [[ "${remote_url}" =~ '^git@([^:]+):' ]]; then
    print -- "${match[1]}"
    return 0
  fi

  if [[ "${remote_url}" =~ '^ssh://git@([^/]+)/' ]]; then
    print -- "${match[1]}"
    return 0
  fi

  if [[ "${remote_url}" =~ '^https://github\.com/' ]]; then
    print -- "github.com"
    return 0
  fi

  return 1
}

_gus_rewrite_remote_url() {
  emulate -L zsh

  local remote_url="$1"
  local target_host="$2"

  if [[ "${remote_url}" =~ '^git@([^:]+):(.*)$' ]]; then
    print -- "git@${target_host}:${match[2]}"
    return 0
  fi

  if [[ "${remote_url}" =~ '^ssh://git@([^/]+)/(.*)$' ]]; then
    print -- "ssh://git@${target_host}/${match[2]}"
    return 0
  fi

  if [[ "${remote_url}" =~ '^https://github\.com/(.*)$' ]]; then
    print -- "git@${target_host}:${match[1]}"
    return 0
  fi

  return 1
}

_gus_remote_points_to_github() {
  emulate -L zsh

  local remote_url="$1"
  local host
  host="$(_gus_parse_remote_host "${remote_url}")" || return 1
  [[ "${host}" == github.com || "${host}" == github-* ]]
}

_gus_update_repo_remotes() {
  emulate -L zsh

  local username="$1"
  local host_alias remote remote_url updated_url
  local -a remotes

  host_alias="$(_gus_user_field "${username}" host_alias)"
  if [[ -z "${host_alias}" ]]; then
    _gus_err "No host_alias configured for user: ${username}"
    return 1
  fi

  if ! _gus_in_git_repo; then
    return 0
  fi

  remotes=( ${(f)$(_gus_remote_names)} )
  for remote in "${remotes[@]}"; do
    remote_url="$(git remote get-url "${remote}" 2>/dev/null)" || continue
    if ! _gus_remote_points_to_github "${remote_url}"; then
      continue
    fi

    updated_url="$(_gus_rewrite_remote_url "${remote_url}" "${host_alias}")" || {
      _gus_err "Unsupported remote format for ${remote}: ${remote_url}"
      return 1
    }

    if [[ "${updated_url}" != "${remote_url}" ]]; then
      git remote set-url "${remote}" "${updated_url}" || {
        _gus_err "Failed to update remote ${remote}"
        return 1
      }
    fi
  done

  return 0
}

_gus_backup_file() {
  emulate -L zsh

  local file_path="$1"
  local timestamp backup_path

  timestamp="$(date +%Y%m%d%H%M%S)"
  backup_path="${file_path}.bak.${timestamp}"
  cp -- "${file_path}" "${backup_path}" || {
    _gus_err "Failed to create backup: ${backup_path}"
    return 1
  }
  print -- "${backup_path}"
}

_gus_ensure_host_alias() {
  emulate -L zsh

  local username="$1"
  local ssh_config="${HOME}/.ssh/config"
  local ssh_dir="${HOME}/.ssh"
  local key_file alias temp_file backup_path block

  alias="$(_gus_user_field "${username}" host_alias)"
  if [[ -z "${alias}" ]]; then
    _gus_err "No host_alias configured for user: ${username}"
    return 1
  fi

  key_file="$(_gus_expand_path "$(_gus_user_field "${username}" key)")"
  if [[ -z "${key_file}" ]]; then
    _gus_err "No SSH key configured for user: ${username}"
    return 1
  fi

  if [[ ! -f "${key_file}" ]]; then
    _gus_err "SSH key not found: ${key_file}"
    return 1
  fi

  mkdir -p -- "${ssh_dir}" || {
    _gus_err "Failed to create SSH directory: ${ssh_dir}"
    return 1
  }
  chmod 700 -- "${ssh_dir}" 2>/dev/null || true

  block=$(cat <<EOF
Host ${alias}
  HostName github.com
  User git
  IdentityFile ${key_file}
  IdentitiesOnly yes
  AddKeysToAgent yes
EOF
)

  if [[ -f "${ssh_config}" ]]; then
    if command grep -q "^Host ${alias}\$" -- "${ssh_config}"; then
      return 0
    fi

    backup_path="$(_gus_backup_file "${ssh_config}")" || return 1
    _gus_info "Created SSH config backup: ${backup_path}"

    temp_file="${ssh_config}.tmp.$$"
    {
      cat -- "${ssh_config}"
      print --
      print -- "${block}"
    } > "${temp_file}" || {
      rm -f -- "${temp_file}"
      _gus_err "Failed to append SSH host alias block"
      return 1
    }

    mv -- "${temp_file}" "${ssh_config}" || {
      rm -f -- "${temp_file}"
      _gus_err "Failed to install updated SSH config"
      return 1
    }
  else
    print -- "${block}" > "${ssh_config}" || {
      _gus_err "Failed to write SSH config"
      return 1
    }
    chmod 600 -- "${ssh_config}" 2>/dev/null || true
  fi

  return 0
}

_gus_magic_ssh_config() {
  emulate -L zsh

  local username="$1"
  local ssh_config="${HOME}/.ssh/config"
  local ssh_dir="${HOME}/.ssh"
  local key_file temp_file backup_path block

  key_file="$(_gus_expand_path "$(_gus_user_field "${username}" key)")"
  if [[ -z "${key_file}" ]]; then
    _gus_err "No SSH key configured for user: ${username}"
    return 1
  fi

  if [[ ! -f "${key_file}" ]]; then
    _gus_err "SSH key not found: ${key_file}"
    return 1
  fi

  mkdir -p -- "${ssh_dir}" || {
    _gus_err "Failed to create SSH directory: ${ssh_dir}"
    return 1
  }

  block=$(cat <<EOF
Host github.com
  HostName github.com
  User git
  IdentityFile ${key_file}
  AddKeysToAgent yes
EOF
)

  temp_file="${ssh_config}.tmp.$$"
  if [[ -f "${ssh_config}" ]]; then
    if [[ "$(cat -- "${ssh_config}")" == *"${block}"* ]]; then
      return 0
    fi

    backup_path="$(_gus_backup_file "${ssh_config}")" || return 1
    _gus_info "Created SSH config backup: ${backup_path}"

    awk -v replacement="${block}" '
      BEGIN { in_block=0; replaced=0 }
      /^Host github\.com$/ {
        if (!replaced) {
          print replacement
          replaced=1
        }
        in_block=1
        next
      }
      in_block && /^Host / {
        in_block=0
      }
      !in_block { print }
      END {
        if (!replaced) {
          if (NR > 0) {
            print ""
          }
          print replacement
        }
      }
    ' "${ssh_config}" > "${temp_file}" || {
      rm -f -- "${temp_file}"
      _gus_err "Failed to rewrite SSH config"
      return 1
    }
  else
    print -- "${block}" > "${temp_file}" || {
      _gus_err "Failed to write SSH config"
      return 1
    }
  fi

  mv -- "${temp_file}" "${ssh_config}" || {
    rm -f -- "${temp_file}"
    _gus_err "Failed to install updated SSH config"
    return 1
  }

  return 0
}

_gus_switch_gh_auth() {
  emulate -L zsh

  local username="$1"
  local gh_user

  if [[ "${GUS_ENABLE_GH_SWITCH}" != "1" ]]; then
    return 0
  fi

  if ! command -v gh &>/dev/null; then
    _gus_info "Skipping gh switch because gh is not installed"
    return 0
  fi

  gh_user="$(_gus_user_field "${username}" gh_user)"
  if [[ -z "${gh_user}" ]]; then
    gh_user="${username}"
  fi

  gh auth switch --user "${gh_user}" &>/dev/null || {
    _gus_err "Failed to switch gh authentication to ${gh_user}. Authenticate it first with gh auth login."
    return 1
  }

  return 0
}

_gus_write_last_user() {
  emulate -L zsh

  _gus_state_mkdir || return 1
  print -- "$1" >| "${GUS_LAST_USER_FILE}" || {
    _gus_err "Failed to write state file: ${GUS_LAST_USER_FILE}"
    return 1
  }
}

_gus_current_gh_user() {
  emulate -L zsh

  local status_line

  if ! command -v gh &>/dev/null; then
    return 1
  fi

  status_line="$(gh auth status 2>&1 | command grep -m1 'Logged in to github.com account ')" || return 1
  if [[ "${status_line}" =~ 'Logged in to github.com account ([^[:space:]]+)' ]]; then
    print -- "${match[1]}"
    return 0
  fi

  return 1
}

_gus_detect_repo_user() {
  emulate -L zsh

  local email host url user

  email="$(_gus_git_email)"
  if [[ -n "${email}" ]]; then
    user="$(_gus_user_for_email "${email}")" && {
      print -- "${user}"
      return 0
    }
  fi

  if _gus_in_git_repo; then
    url="$(git remote get-url origin 2>/dev/null)"
    if [[ -n "${url}" ]]; then
      host="$(_gus_parse_remote_host "${url}")" && {
        user="$(_gus_user_for_alias "${host}")" && {
          print -- "${user}"
          return 0
        }
      }
    fi
  fi

  if [[ -f "${GUS_LAST_USER_FILE}" ]]; then
    cat -- "${GUS_LAST_USER_FILE}" 2>/dev/null
    return 0
  fi

  return 1
}

_gus_apply_user() {
  emulate -L zsh

  local username="$1"
  local set_git="$2"
  local quiet="$3"
  local git_name git_email repo_root ssh_target

  if ! _gus_user_exists "${username}"; then
    _gus_err "Unknown user: ${username}"
    return 1
  fi

  git_name="$(_gus_user_field "${username}" name)"
  git_email="$(_gus_user_field "${username}" email)"

  if [[ "${set_git}" == "1" ]]; then
    if ! _gus_in_git_repo; then
      _gus_err "Not in a git repository"
      return 1
    fi

    git config --local user.name "${git_name}" || {
      _gus_err "Failed to set git user.name"
      return 1
    }
    git config --local user.email "${git_email}" || {
      _gus_err "Failed to set git user.email"
      return 1
    }
  fi

  if [[ "${GUS_MODE}" == "safe" ]]; then
    _gus_ensure_host_alias "${username}" || return 1
    _gus_update_repo_remotes "${username}" || return 1
    ssh_target="$(_gus_user_field "${username}" host_alias)"
  elif [[ "${GUS_MODE}" == "magic" ]]; then
    _gus_magic_ssh_config "${username}" || return 1
    ssh_target="github.com"
  else
    _gus_err "Unsupported GUS_MODE: ${GUS_MODE}. Expected safe or magic."
    return 1
  fi

  _gus_switch_gh_auth "${username}" || return 1
  _gus_write_last_user "${username}" || return 1

  if [[ "${quiet}" != "1" ]]; then
    repo_root="$(_gus_repo_root)"
    print -- "✓ Active user: ${username}"
    print -- "  Mode: ${GUS_MODE}"
    print -- "  Git email: ${git_email}"
    print -- "  SSH: ${ssh_target}"
    if [[ -n "${repo_root}" ]]; then
      print -- "  Repo: ${repo_root}"
    fi
  fi

  return 0
}

_gus_auto_switch() {
  emulate -L zsh

  local email username

  if [[ "${GUS_AUTO_SWITCH}" != "1" ]]; then
    return 0
  fi

  if [[ -f "${GUS_AUTO_SWITCH_LOCK_FILE}" ]]; then
    return 0
  fi

  if ! _gus_in_git_repo; then
    return 0
  fi

  email="$(_gus_git_email)"
  if [[ -z "${email}" ]]; then
    return 0
  fi

  username="$(_gus_user_for_email "${email}")" || return 0
  _gus_apply_user "${username}" 0 1 || {
    _gus_notice "gus auto-switch failed: ${GUS_LAST_ERROR}"
    return 1
  }

  _gus_notice "gus active user: ${username}"
  return 0
}

_gus_list() {
  emulate -L zsh

  local user
  local -a users

  _gus_collect_users users
  for user in "${users[@]}"; do
    print -- "${user}"
    print -- "  Name: $(_gus_user_field "${user}" name)"
    print -- "  Email: $(_gus_user_field "${user}" email)"
    print -- "  SSH key: $(_gus_user_field "${user}" key)"
    print -- "  Host alias: $(_gus_user_field "${user}" host_alias)"
  done
}

_gus_status() {
  emulate -L zsh

  local active_user repo_root git_name git_email origin_url remote_host remote_user gh_user

  active_user="$(_gus_detect_repo_user 2>/dev/null)"
  repo_root="$(_gus_repo_root)"
  git_name="$(_gus_git_name)"
  git_email="$(_gus_git_email)"
  origin_url="$(git remote get-url origin 2>/dev/null)"
  remote_host="$(_gus_parse_remote_host "${origin_url}" 2>/dev/null)"
  remote_user="$(_gus_user_for_alias "${remote_host}" 2>/dev/null)"
  gh_user="$(_gus_current_gh_user 2>/dev/null)"

  print -- "GUS status"
  print -- "  Mode: ${GUS_MODE}"
  print -- "  Config: ${GUS_CONFIG_SOURCE:-uninitialized}"
  print -- "  Active user: ${active_user:-unknown}"
  print -- "  Repo: ${repo_root:-not in git repo}"
  print -- "  Git name: ${git_name:-unset}"
  print -- "  Git email: ${git_email:-unset}"
  print -- "  Origin: ${origin_url:-unset}"
  print -- "  Remote host: ${remote_host:-unset}"
  print -- "  Remote user: ${remote_user:-unknown}"
  print -- "  gh user: ${gh_user:-unavailable}"
}

_gus_doctor() {
  emulate -L zsh

  local ok=1 user key alias ssh_config remote_url
  local -a users

  print -- "GUS doctor"
  print -- "  Config source: ${GUS_CONFIG_SOURCE}"

  _gus_validate_config || return 1
  print -- "  ✓ Config validated"

  _gus_collect_users users
  for user in "${users[@]}"; do
    key="$(_gus_expand_path "$(_gus_user_field "${user}" key)")"
    alias="$(_gus_user_field "${user}" host_alias)"
    if [[ -f "${key}" ]]; then
      print -- "  ✓ ${user} key exists: ${key}"
    else
      print -- "  ✗ ${user} key missing: ${key}"
      ok=0
    fi

    if [[ "${GUS_MODE}" == "safe" ]]; then
      ssh_config="${HOME}/.ssh/config"
      if [[ -f "${ssh_config}" ]] && grep -q "^Host ${alias}$" "${ssh_config}"; then
        print -- "  ✓ ${user} host alias present: ${alias}"
      else
        print -- "  ! ${user} host alias not found in ${ssh_config}: ${alias}"
      fi
    fi
  done

  if command -v gh &>/dev/null; then
    print -- "  ✓ gh installed"
  else
    print -- "  ! gh not installed"
  fi

  if _gus_in_git_repo; then
    remote_url="$(git remote get-url origin 2>/dev/null)"
    if [[ -n "${remote_url}" ]]; then
      print -- "  ✓ origin remote detected: ${remote_url}"
    else
      print -- "  ! no origin remote configured"
    fi
  else
    print -- "  ! not in a git repository"
  fi

  (( ok == 1 ))
}

_gus_help() {
  emulate -L zsh

  cat <<EOF
Git User Switch

Primary mode: Safe & Predictable
  - No global SSH mutation in normal operation
  - Per-repo remote rewriting to configured SSH host aliases

Commands:
  gus switch <user>   Switch active user for the current repo and gh
  gus appoint <user>  Set git user.name/email for this repo and align auth
  gus status          Show derived git/ssh/gh state
  gus list            List configured users
  gus doctor          Validate config, keys, remotes, and gh availability
  gus help            Show this help

Compatibility:
  gus <user>          Alias for gus switch <user>
  gus-appoint <user>  Alias for gus appoint <user>

Config:
  File: ${GUS_CONFIG_FILE}
  Format: associative array entries like user:key, user:email, user:name, user:host_alias
  Mode: set GUS_MODE=safe or GUS_MODE=magic before loading the plugin
EOF
}

gus() {
  emulate -L zsh

  local command="$1"
  local username="$2"

  if [[ -z "${GUS_CONFIG_SOURCE}" ]]; then
    _gus_init || return 1
  fi

  case "${command}" in
    "")
      _gus_help
      return 1
      ;;
    help|-h|--help)
      _gus_help
      ;;
    switch)
      if [[ -z "${username}" ]]; then
        _gus_err "Usage: gus switch <user>"
        return 1
      fi
      _gus_apply_user "${username}" 0 0
      ;;
    appoint)
      if [[ -z "${username}" ]]; then
        _gus_err "Usage: gus appoint <user>"
        return 1
      fi
      _gus_apply_user "${username}" 1 0
      ;;
    status)
      _gus_status
      ;;
    list)
      _gus_list
      ;;
    doctor)
      _gus_doctor
      ;;
    lock)
      _gus_state_mkdir || return 1
      : >| "${GUS_AUTO_SWITCH_LOCK_FILE}" || return 1
      print -- "✓ Auto-switch locked"
      ;;
    unlock)
      rm -f -- "${GUS_AUTO_SWITCH_LOCK_FILE}"
      print -- "✓ Auto-switch unlocked"
      ;;
    *)
      if _gus_user_exists "${command}"; then
        print -u2 -- "[git-user-switch] 'gus ${command}' is deprecated. Use 'gus switch ${command}'."
        _gus_apply_user "${command}" 0 0
      else
        _gus_err "Unknown command or user: ${command}"
        _gus_help
        return 1
      fi
      ;;
  esac
}

gus-appoint() {
  emulate -L zsh

  if [[ -z "${GUS_CONFIG_SOURCE}" ]]; then
    _gus_init || return 1
  fi

  print -u2 -- "[git-user-switch] 'gus-appoint' is deprecated. Use 'gus appoint <user>'."
  gus appoint "$1"
}

git_user_switch_plugin_unload() {
  emulate -L zsh

  if (( ${+functions[add-zsh-hook]} )); then
    add-zsh-hook -d chpwd _gus_auto_switch
  fi

  unfunction gus 2>/dev/null
  unfunction gus-appoint 2>/dev/null
  unfunction _gus_err 2>/dev/null
  unfunction _gus_info 2>/dev/null
  unfunction _gus_notice 2>/dev/null
  unfunction _gus_state_mkdir 2>/dev/null
  unfunction _gus_expand_path 2>/dev/null
  unfunction _gus_collect_users 2>/dev/null
  unfunction _gus_user_field 2>/dev/null
  unfunction _gus_set_user_field_if_empty 2>/dev/null
  unfunction _gus_default_config 2>/dev/null
  unfunction _gus_import_legacy_config 2>/dev/null
  unfunction _gus_load_config_file 2>/dev/null
  unfunction _gus_validate_config 2>/dev/null
  unfunction _gus_init 2>/dev/null
  unfunction _gus_user_exists 2>/dev/null
  unfunction _gus_user_for_email 2>/dev/null
  unfunction _gus_user_for_alias 2>/dev/null
  unfunction _gus_in_git_repo 2>/dev/null
  unfunction _gus_repo_root 2>/dev/null
  unfunction _gus_git_config_get 2>/dev/null
  unfunction _gus_git_email 2>/dev/null
  unfunction _gus_git_name 2>/dev/null
  unfunction _gus_remote_names 2>/dev/null
  unfunction _gus_parse_remote_host 2>/dev/null
  unfunction _gus_rewrite_remote_url 2>/dev/null
  unfunction _gus_remote_points_to_github 2>/dev/null
  unfunction _gus_update_repo_remotes 2>/dev/null
  unfunction _gus_backup_file 2>/dev/null
  unfunction _gus_ensure_host_alias 2>/dev/null
  unfunction _gus_magic_ssh_config 2>/dev/null
  unfunction _gus_switch_gh_auth 2>/dev/null
  unfunction _gus_write_last_user 2>/dev/null
  unfunction _gus_current_gh_user 2>/dev/null
  unfunction _gus_detect_repo_user 2>/dev/null
  unfunction _gus_apply_user 2>/dev/null
  unfunction _gus_auto_switch 2>/dev/null
  unfunction _gus_list 2>/dev/null
  unfunction _gus_status 2>/dev/null
  unfunction _gus_doctor 2>/dev/null
  unfunction _gus_help 2>/dev/null
  unfunction git_user_switch_plugin_unload 2>/dev/null

  unset 'Plugins[GIT_USER_SWITCH_DIR]'
  unset GUS_CONFIG_SOURCE
  unset GUS_LAST_ERROR
}

autoload -Uz add-zsh-hook

_gus_init || return 1
add-zsh-hook chpwd _gus_auto_switch
_gus_auto_switch

if [[ -n "${zsh_loaded_plugins-}" ]]; then
  zsh_loaded_plugins+=("${0:h:t}")
fi
