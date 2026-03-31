#!/usr/bin/env zsh
# Edge case tests for git-user-switch plugin

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

PASS=0
FAIL=0

assert_exit() {
  local expected="$1"
  local actual="$2"
  local message="$3"
  if [[ "${actual}" == "${expected}" ]]; then
    PASS=$((PASS + 1))
    print -- "  PASS: ${message}"
  else
    FAIL=$((FAIL + 1))
    print -u2 -- "  FAIL: ${message} (expected exit ${expected}, got ${actual})"
  fi
}

assert_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "${haystack}" == *"${needle}"* ]]; then
    PASS=$((PASS + 1))
    print -- "  PASS: ${message}"
  else
    FAIL=$((FAIL + 1))
    print -u2 -- "  FAIL: ${message}"
    print -u2 -- "    missing: ${needle}"
    print -u2 -- "    output: ${haystack}"
  fi
}

assert_not_contains() {
  local haystack="$1"
  local needle="$2"
  local message="$3"
  if [[ "${haystack}" != *"${needle}"* ]]; then
    PASS=$((PASS + 1))
    print -- "  PASS: ${message}"
  else
    FAIL=$((FAIL + 1))
    print -u2 -- "  FAIL: ${message}"
    print -u2 -- "    should not contain: ${needle}"
  fi
}

source "${SCRIPT_DIR}/git-user-switch.plugin.zsh"

print -- "=== Edge Case Tests ==="

# --- Test: gus with no arguments ---
print -- "--- gus (no args) ---"
output="$(gus 2>&1)" || true
assert_contains "${output}" "Commands:" "gus with no args shows help"

# --- Test: gus help ---
print -- "--- gus help ---"
output="$(gus help 2>&1)"
assert_contains "${output}" "gus switch" "help mentions switch command"
assert_contains "${output}" "gus appoint" "help mentions appoint command"

# --- Test: gus list ---
print -- "--- gus list ---"
output="$(gus list 2>&1)"
assert_contains "${output}" "personal" "list shows personal user"
assert_contains "${output}" "work" "list shows work user"

# --- Test: gus switch with no user ---
print -- "--- gus switch (no user) ---"
output="$(gus switch 2>&1)" && rc=0 || rc=$?
assert_exit "1" "${rc}" "gus switch with no user exits 1"
assert_contains "${output}" "Usage:" "gus switch with no user shows usage"

# --- Test: gus appoint with no user ---
print -- "--- gus appoint (no user) ---"
output="$(gus appoint 2>&1)" && rc=0 || rc=$?
assert_exit "1" "${rc}" "gus appoint with no user exits 1"
assert_contains "${output}" "Usage:" "gus appoint with no user shows usage"

# --- Test: gus switch unknown user ---
print -- "--- gus switch unknown-user ---"
output="$(gus switch nonexistent 2>&1)" && rc=0 || rc=$?
assert_exit "1" "${rc}" "gus switch unknown user exits 1"
assert_contains "${output}" "Unknown user" "gus switch unknown user reports error"

# --- Test: gus status outside a repo ---
print -- "--- gus status (not in repo) ---"
pushd "${TMP_DIR}" >/dev/null
output="$(gus status 2>&1)"
assert_contains "${output}" "not in git repo" "status outside repo says so"
popd >/dev/null

# --- Test: gus doctor outside a repo ---
print -- "--- gus doctor (not in repo) ---"
pushd "${TMP_DIR}" >/dev/null
output="$(gus doctor 2>&1)"
assert_contains "${output}" "not in a git repository" "doctor outside repo says so"
popd >/dev/null

# --- Test: gus unknown command ---
print -- "--- gus badcommand ---"
output="$(gus badcommand 2>&1)" && rc=0 || rc=$?
assert_exit "1" "${rc}" "gus badcommand exits 1"
assert_contains "${output}" "Unknown command" "gus badcommand reports error"

# --- Test: gus switch idempotency (switch same user twice) ---
print -- "--- idempotency ---"
REPO_DIR="${TMP_DIR}/idempotent-repo"
mkdir -p "${REPO_DIR}" && cd "${REPO_DIR}"
git init -q
git remote add origin git@github.com:owner/project.git
gus appoint personal >/dev/null 2>&1
output1="$(git remote get-url origin)"
gus appoint personal >/dev/null 2>&1
output2="$(git remote get-url origin)"
if [[ "${output1}" == "${output2}" ]]; then
  PASS=$((PASS + 1))
  print -- "  PASS: idempotent appoint does not change remote"
else
  FAIL=$((FAIL + 1))
  print -u2 -- "  FAIL: appoint changed remote on second run: ${output1} -> ${output2}"
fi

# --- Test: switch does NOT set git config ---
print -- "--- switch vs appoint git config ---"
gus appoint work >/dev/null 2>&1
assert_contains "$(git config --local user.email)" "work@example.com" "appoint sets email"
gus switch personal >/dev/null 2>&1
# switch should NOT change the local git email (only appoint does)
assert_contains "$(git config --local user.email)" "work@example.com" "switch preserves repo email"

# --- Test: HTTPS remote rewriting ---
print -- "--- HTTPS remote ---"
REPO2="${TMP_DIR}/https-repo"
mkdir -p "${REPO2}" && cd "${REPO2}"
git init -q
git remote add origin https://github.com/owner/project.git
gus appoint personal >/dev/null 2>&1
url="$(git remote get-url origin)"
assert_contains "${url}" "github-personal" "HTTPS remote is rewritten to SSH alias"
assert_not_contains "${url}" "https://" "HTTPS is converted to SSH"

# --- Test: non-github remote is left alone ---
print -- "--- non-github remote ---"
REPO3="${TMP_DIR}/gitlab-repo"
mkdir -p "${REPO3}" && cd "${REPO3}"
git init -q
git remote add origin git@gitlab.com:owner/project.git
gus appoint personal >/dev/null 2>&1
url="$(git remote get-url origin)"
assert_contains "${url}" "gitlab.com" "non-github remote is not rewritten"

# --- Test: lock/unlock ---
print -- "--- lock/unlock ---"
cd "${REPO_DIR}"
output="$(gus lock 2>&1)"
assert_contains "${output}" "locked" "lock confirms"
if [[ -f "${GUS_AUTO_SWITCH_LOCK_FILE}" ]]; then
  PASS=$((PASS + 1))
  print -- "  PASS: lock file created"
else
  FAIL=$((FAIL + 1))
  print -u2 -- "  FAIL: lock file not created"
fi

output="$(gus unlock 2>&1)"
assert_contains "${output}" "unlocked" "unlock confirms"
if [[ ! -f "${GUS_AUTO_SWITCH_LOCK_FILE}" ]]; then
  PASS=$((PASS + 1))
  print -- "  PASS: lock file removed"
else
  FAIL=$((FAIL + 1))
  print -u2 -- "  FAIL: lock file still exists"
fi

# --- Test: auto-switch respects lock ---
print -- "--- auto-switch lock ---"
cd "${REPO_DIR}"
gus appoint work >/dev/null 2>&1
gus lock >/dev/null 2>&1
# auto-switch should be a no-op when locked
_gus_auto_switch 2>/dev/null
gh_user_after="$(cat -- "${GUS_TEST_GH_STATE}")"
assert_contains "${gh_user_after}" "work-gh" "auto-switch is blocked by lock"
gus unlock >/dev/null 2>&1

# --- Test: gus-appoint compat shim ---
print -- "--- gus-appoint compat ---"
cd "${REPO_DIR}"
output="$(gus-appoint personal 2>&1)"
assert_contains "${output}" "deprecated" "gus-appoint warns about deprecation"
assert_contains "${output}" "✓ Active user: personal" "gus-appoint still works"

# --- Test: unload removes all functions ---
print -- "--- unload ---"
git_user_switch_plugin_unload
funcs_remaining=""
for fn in gus gus-appoint _gus_err _gus_info _gus_apply_user _gus_init; do
  if (( ${+functions[$fn]} )); then
    funcs_remaining+="${fn} "
  fi
done
if [[ -z "${funcs_remaining}" ]]; then
  PASS=$((PASS + 1))
  print -- "  PASS: all functions cleaned up"
else
  FAIL=$((FAIL + 1))
  print -u2 -- "  FAIL: functions still defined: ${funcs_remaining}"
fi

# --- Summary ---
print -- ""
print -- "=== Results: ${PASS} passed, ${FAIL} failed ==="
(( FAIL == 0 ))
