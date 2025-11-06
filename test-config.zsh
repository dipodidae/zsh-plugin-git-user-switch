#!/usr/bin/env zsh
# Test script for configuration functionality

echo "=== Testing Configuration System ==="
echo ""

# Test 1: Custom configuration before loading
echo "Test 1: Testing custom configuration..."
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "custom-user1" "~/.ssh/custom_key1"
  "custom-user2" "~/.ssh/custom_key2"
)

source "${0:A:h}/git-user-switch.plugin.zsh"

if [[ "${GUS_USER_KEYS[custom-user1]}" == "~/.ssh/custom_key1" ]] && \
   [[ "${GUS_USER_KEYS[custom-user2]}" == "~/.ssh/custom_key2" ]]; then
  echo "✓ PASS: Custom configuration preserved"
  echo "  custom-user1 → ${GUS_USER_KEYS[custom-user1]}"
  echo "  custom-user2 → ${GUS_USER_KEYS[custom-user2]}"
else
  echo "✗ FAIL: Custom configuration not preserved"
  exit 1
fi
echo ""

# Verify the custom users are recognized
echo "Test 2: Testing custom users are recognized..."
if gus 2>&1 | grep -q "custom-user1"; then
  echo "✓ PASS: Custom users appear in error message"
else
  echo "✗ FAIL: Custom users not recognized"
  exit 1
fi
echo ""

# Clean up and reload to test defaults
echo "Test 3: Testing default configuration..."
unfunction gus .gus_err .gus_update_ssh_config .gus_switch_gh_auth git_user_switch_plugin_unload
unset GUS_USER_KEYS
source "${0:A:h}/git-user-switch.plugin.zsh"

if [[ "${GUS_USER_KEYS[dipodidae]}" == "~/.ssh/dipodidae" ]] && \
   [[ "${GUS_USER_KEYS[spend-cloud-tom]}" == "~/.ssh/spend-cloud-tom" ]]; then
  echo "✓ PASS: Default configuration loaded"
  echo "  dipodidae → ${GUS_USER_KEYS[dipodidae]}"
  echo "  spend-cloud-tom → ${GUS_USER_KEYS[spend-cloud-tom]}"
else
  echo "✗ FAIL: Default configuration incorrect"
  echo "  dipodidae → ${GUS_USER_KEYS[dipodidae]}"
  echo "  spend-cloud-tom → ${GUS_USER_KEYS[spend-cloud-tom]}"
  exit 1
fi
echo ""

echo "Test 4: Testing user list generation..."
if gus 2>&1 | grep -q "dipodidae"; then
  echo "✓ PASS: Default users appear in help message"
else
  echo "✗ FAIL: Default users not in help message"
  exit 1
fi
echo ""

echo "=== All Configuration Tests Passed! ==="
echo ""
echo "Configuration system is working correctly:"
echo "  ✓ Custom configurations are respected"
echo "  ✓ Default configuration works when not customized"
echo "  ✓ Users can be dynamically added"
echo ""
echo "Example .zshrc configuration:"
echo ""
echo "  typeset -gA GUS_USER_KEYS"
echo "  GUS_USER_KEYS=("
echo "    \"dipodidae\"       \"~/.ssh/dipodidae\""
echo "    \"spend-cloud-tom\" \"~/.ssh/spend-cloud-tom\""
echo "  )"
echo "  source /path/to/git-user-switch.plugin.zsh"
