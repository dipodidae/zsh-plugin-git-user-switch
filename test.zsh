#!/usr/bin/env zsh
#
# Test script for git-user-switch plugin
# This tests the plugin functionality without actually modifying your SSH config

# Source the plugin
SCRIPT_DIR="${0:A:h}"
source "${SCRIPT_DIR}/git-user-switch.plugin.zsh"

echo "=== Git User Switch Plugin Test ==="
echo ""

# Test 1: Check if gus function exists
echo "Test 1: Checking if gus function exists..."
if (( ${+functions[gus]} )); then
  echo "✓ PASS: gus function is defined"
else
  echo "✗ FAIL: gus function is not defined"
  exit 1
fi
echo ""

# Test 2: Check if helper functions exist
echo "Test 2: Checking helper functions..."
local -a required_functions
required_functions=(
  .gus_err
  .gus_update_ssh_config
  .gus_switch_gh_auth
  gus-appoint
  git_user_switch_plugin_unload
)

for func in "${required_functions[@]}"; do
  if (( ${+functions[$func]} )); then
    echo "✓ PASS: ${func} is defined"
  else
    echo "✗ FAIL: ${func} is not defined"
    exit 1
  fi
done
echo ""

# Test 3: Check plugin hash
echo "Test 3: Checking Plugins hash..."
if [[ -n "${Plugins[GIT_USER_SWITCH_DIR]}" ]]; then
  echo "✓ PASS: Plugins[GIT_USER_SWITCH_DIR] is set to: ${Plugins[GIT_USER_SWITCH_DIR]}"
else
  echo "✗ FAIL: Plugins[GIT_USER_SWITCH_DIR] is not set"
  exit 1
fi
echo ""

# Test 3.5: Check configuration hashes
echo "Test 3.5: Checking configuration hashes..."
if (( ${#GUS_USER_KEYS[@]} > 0 )); then
  echo "✓ PASS: GUS_USER_KEYS is configured with ${#GUS_USER_KEYS[@]} users"
else
  echo "✗ FAIL: GUS_USER_KEYS is not configured"
  exit 1
fi

if (( ${#GUS_EMAIL_TO_USER[@]} > 0 )); then
  echo "✓ PASS: GUS_EMAIL_TO_USER is configured with ${#GUS_EMAIL_TO_USER[@]} mappings"
else
  echo "✗ FAIL: GUS_EMAIL_TO_USER is not configured"
  exit 1
fi

if (( ${#GUS_USER_EMAILS[@]} > 0 )); then
  echo "✓ PASS: GUS_USER_EMAILS is configured with ${#GUS_USER_EMAILS[@]} mappings"
else
  echo "✗ FAIL: GUS_USER_EMAILS is not configured"
  exit 1
fi

if (( ${#GUS_USER_NAMES[@]} > 0 )); then
  echo "✓ PASS: GUS_USER_NAMES is configured with ${#GUS_USER_NAMES[@]} mappings"
else
  echo "✗ FAIL: GUS_USER_NAMES is not configured"
  exit 1
fi
echo ""

# Test 4: Test error handling (no arguments)
echo "Test 4: Testing error handling (no arguments)..."
if gus 2>/dev/null; then
  echo "✗ FAIL: gus should fail without arguments"
  exit 1
else
  echo "✓ PASS: gus correctly fails without arguments"
fi
echo ""

# Test 5: Test error handling (invalid user)
echo "Test 5: Testing error handling (invalid user)..."
if gus invalid-user 2>/dev/null; then
  echo "✗ FAIL: gus should fail with invalid username"
  exit 1
else
  echo "✓ PASS: gus correctly fails with invalid username"
fi
echo ""

# Test 6: Test unload function
echo "Test 6: Testing unload function..."
git_user_switch_plugin_unload
if (( ${+functions[gus]} )); then
  echo "✗ FAIL: gus function still exists after unload"
  exit 1
else
  echo "✓ PASS: gus function was unloaded"
fi

if [[ -z "${Plugins[GIT_USER_SWITCH_DIR]}" ]]; then
  echo "✓ PASS: Plugin data was cleaned up"
else
  echo "✗ FAIL: Plugin data still exists: ${Plugins[GIT_USER_SWITCH_DIR]}"
  exit 1
fi
echo ""

echo "=== All Tests Passed! ==="
echo ""
echo "To actually use the plugin, source it in your .zshrc:"
echo "  source ${SCRIPT_DIR}/git-user-switch.plugin.zsh"
echo ""
echo "Then run:"
echo "  gus dipodidae"
echo "  gus spend-cloud-tom"
