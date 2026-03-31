#!/usr/bin/env zsh

emulate -L zsh
setopt errexit nounset pipefail

SCRIPT_DIR="${0:A:h}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf -- "${TMP_DIR}"' EXIT

export HOME="${TMP_DIR}/home"
export XDG_CONFIG_HOME="${TMP_DIR}/config"
export XDG_STATE_HOME="${TMP_DIR}/state"
export GUS_TEST_GH_STATE="${TMP_DIR}/gh-user"
export PATH="${TMP_DIR}/bin:${PATH}"
export GUS_MODE="magic"

mkdir -p -- "${HOME}/.ssh" "${TMP_DIR}/bin"
touch -- "${HOME}/.ssh/legacy"
chmod 600 -- "${HOME}/.ssh/legacy"
print -- "legacy-gh" >| "${GUS_TEST_GH_STATE}"

cat > "${HOME}/.ssh/config" <<'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/old-key
EOF

cat > "${TMP_DIR}/bin/gh" <<'EOF'
#!/bin/sh
state="${GUS_TEST_GH_STATE}"
case "$1 $2" in
  "auth switch")
    if [ "$3" = "--user" ] && [ -n "$4" ]; then
      printf '%s\n' "$4" > "$state"
      exit 0
    fi
    exit 1
    ;;
  "auth status")
    user="unknown"
    if [ -f "$state" ]; then
      user=$(cat "$state")
    fi
    printf 'Logged in to github.com account %s\n' "$user"
    exit 0
    ;;
esac
exit 1
EOF
chmod +x -- "${TMP_DIR}/bin/gh"

typeset -gA GUS_USER_KEYS
typeset -gA GUS_USER_EMAILS
typeset -gA GUS_USER_NAMES
typeset -gA GUS_EMAIL_TO_USER

GUS_USER_KEYS=(
  legacy "~/.ssh/legacy"
)
GUS_USER_EMAILS=(
  legacy "legacy@example.com"
)
GUS_USER_NAMES=(
  legacy "Legacy User"
)
GUS_EMAIL_TO_USER=(
  legacy@example.com legacy
)

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"

  if [[ "${haystack}" != *"${needle}"* ]]; then
    print -u2 -- "FAIL: ${message}"
    print -u2 -- "  missing: ${needle}"
    print -u2 -- "  output: ${haystack}"
    exit 1
  fi
}

source "${SCRIPT_DIR}/git-user-switch.plugin.zsh"

list_output="$(gus list)"
assert_contains "${list_output}" "legacy" "legacy mappings should import into GUS_USERS"
assert_contains "${list_output}" "github-legacy" "legacy mappings should derive default host alias"

REPO_DIR="${TMP_DIR}/repo"
mkdir -p -- "${REPO_DIR}"
cd -- "${REPO_DIR}"
git init -q

appoint_output="$(gus appoint legacy)"
assert_contains "${appoint_output}" "✓ Active user: legacy" "magic mode appoint should succeed"
assert_contains "$(cat -- "${HOME}/.ssh/config")" "IdentityFile ${HOME}/.ssh/legacy" "magic mode should create github.com block"

switch_output="$(gus switch legacy)"
assert_contains "${switch_output}" "✓ Active user: legacy" "magic mode switch should be idempotent on repeated runs"

backup_count="$(find "${HOME}/.ssh" -maxdepth 1 -name 'config.bak.*' | wc -l)"
assert_contains "${backup_count}" "1" "magic mode should create a timestamped backup on rewrite"

print -- "PASS: legacy config and magic mode coverage"