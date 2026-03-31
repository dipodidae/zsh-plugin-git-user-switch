#!/usr/bin/env zsh
emulate -L zsh
setopt nounset

# Test regex matching for HTTPS URLs
url="https://github.com/owner/project.git"

echo "Testing _gus_parse_remote_host regex..."
if [[ "${url}" =~ '^https://github\.com/' ]]; then
  echo "  MATCH (single backslash)"
else
  echo "  NO MATCH (single backslash)"
fi

if [[ "${url}" =~ '^https://github\\.com/' ]]; then
  echo "  MATCH (double backslash)"
else
  echo "  NO MATCH (double backslash)"
fi

echo ""
echo "Testing _gus_rewrite_remote_url regex..."
if [[ "${url}" =~ '^https://github\.com/(.*)$' ]]; then
  echo "  MATCH (single backslash): match[1]=${match[1]}"
else
  echo "  NO MATCH (single backslash)"
fi

if [[ "${url}" =~ '^https://github\\.com/(.*)$' ]]; then
  echo "  MATCH (double backslash): match[1]=${match[1]}"
else
  echo "  NO MATCH (double backslash)"
fi
