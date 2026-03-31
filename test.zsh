#!/usr/bin/env zsh
#
# Test script for git-user-switch plugin
# This tests the plugin functionality without actually modifying your SSH config

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

mkdir -p -- "${HOME}/.ssh" "${XDG_CONFIG_HOME}/git-user-switch" "${XDG_STATE_HOME}" "${TMP_DIR}/bin"
touch -- "${HOME}/.ssh/personal" "${HOME}/.ssh/work"
chmod 600 -- "${HOME}/.ssh/personal" "${HOME}/.ssh/work"

cat > "${HOME}/.ssh/config" <<'EOF'
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/work
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
print -- "personal-gh" >| "${GUS_TEST_GH_STATE}"

cat > "${XDG_CONFIG_HOME}/git-user-switch/config.zsh" <<'EOF'
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
EOF

assert_eq() {
  local actual="$1"
  local expected="$2"
  local message="$3"

  if [[ "${actual}" != "${expected}" ]]; then
    print -u2 -- "FAIL: ${message}"
    print -u2 -- "  expected: ${expected}"
    print -u2 -- "  actual:   ${actual}"
    exit 1
  fi
}

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

print -- "=== Behavioral Test: safe mode ==="

list_output="$(gus list)"
assert_contains "${list_output}" "personal" "gus list should include personal"
assert_contains "${list_output}" "github-work" "gus list should include host alias"

REPO_DIR="${TMP_DIR}/repo"
mkdir -p -- "${REPO_DIR}"
cd -- "${REPO_DIR}"
git init -q
git remote add origin git@github.com:owner/project.git

appoint_output="$(gus appoint work)"
assert_contains "${appoint_output}" "✓ Active user: work" "gus appoint should report active user"
assert_eq "$(git config --local --get user.name)" "Work User" "gus appoint should set git user.name"
assert_eq "$(git config --local --get user.email)" "work@example.com" "gus appoint should set git user.email"
assert_eq "$(git remote get-url origin)" "git@github-work:owner/project.git" "gus appoint should rewrite origin to work alias"
assert_eq "$(cat -- "${GUS_TEST_GH_STATE}")" "work-gh" "gus appoint should switch gh user"

switch_output="$(gus switch personal)"
assert_contains "${switch_output}" "✓ Active user: personal" "gus switch should report active user"
assert_eq "$(git config --local --get user.email)" "work@example.com" "gus switch should not change repo email"
assert_eq "$(git remote get-url origin)" "git@github-personal:owner/project.git" "gus switch should rewrite origin to personal alias"
assert_eq "$(cat -- "${GUS_TEST_GH_STATE}")" "personal-gh" "gus switch should switch gh user"

status_output="$(gus status)"
assert_contains "${status_output}" "Active user: work" "gus status should derive active user from repo email"
assert_contains "${status_output}" "Remote user: personal" "gus status should detect remote alias separately"

doctor_output="$(gus doctor)"
assert_contains "${doctor_output}" "Config validated" "gus doctor should validate config"

compat_output="$(gus work 2>"${TMP_DIR}/compat.err")"
assert_contains "${compat_output}" "✓ Active user: work" "legacy gus <user> should still switch"
assert_contains "$(cat -- "${TMP_DIR}/compat.err")" "deprecated" "legacy gus <user> should warn"

git_user_switch_plugin_unload
if (( ${+functions[gus]} )); then
  print -u2 -- "FAIL: gus should be undefined after unload"
  exit 1
fi

print -- "PASS: safe mode behavioral coverage"
