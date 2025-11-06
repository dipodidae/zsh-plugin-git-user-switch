#!/usr/bin/env zsh
# Example configuration for git-user-switch plugin
# Place this in your ~/.zshrc BEFORE loading the plugin

# ============================================================================
# BASIC CONFIGURATION
# ============================================================================

# Configure user-to-SSH-key mappings
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
)

# ============================================================================
# AUTO-SWITCH CONFIGURATION
# ============================================================================

# Configure email-to-username mappings for auto-switching
# This maps git user.email to GitHub username
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "dipodidae@users.noreply.github.com"       "dipodidae"
  "spend-cloud-tom@users.noreply.github.com" "spend-cloud-tom"
)

# Configure username-to-email mappings (for gus-appoint command)
# This maps GitHub username to git user.email
typeset -gA GUS_USER_EMAILS
GUS_USER_EMAILS=(
  "dipodidae"       "dipodidae@users.noreply.github.com"
  "spend-cloud-tom" "spend-cloud-tom@users.noreply.github.com"
)

# Configure username-to-name mappings (for gus-appoint command)
# This maps GitHub username to git user.name
typeset -gA GUS_USER_NAMES
GUS_USER_NAMES=(
  "dipodidae"       "dipodidae"
  "spend-cloud-tom" "Tom"
)

# Enable/disable auto-switching (1 = enabled, 0 = disabled)
# Default: 1 (enabled)
typeset -g GUS_AUTO_SWITCH=1

# ============================================================================
# ADVANCED EXAMPLES
# ============================================================================

# Example 1: Multiple work accounts
# typeset -gA GUS_USER_KEYS
# GUS_USER_KEYS=(
#   "personal"     "~/.ssh/id_rsa_personal"
#   "work-acme"    "~/.ssh/id_rsa_work_acme"
#   "work-startup" "~/.ssh/id_rsa_work_startup"
#   "client-xyz"   "~/.ssh/id_rsa_client_xyz"
# )
#
# typeset -gA GUS_EMAIL_TO_USER
# GUS_EMAIL_TO_USER=(
#   "me@personal.com"           "personal"
#   "john.doe@acme.com"         "work-acme"
#   "john@startup.io"           "work-startup"
#   "contractor@xyzcorp.com"    "client-xyz"
# )
#
# typeset -gA GUS_USER_EMAILS
# GUS_USER_EMAILS=(
#   "personal"     "me@personal.com"
#   "work-acme"    "john.doe@acme.com"
#   "work-startup" "john@startup.io"
#   "client-xyz"   "contractor@xyzcorp.com"
# )
#
# typeset -gA GUS_USER_NAMES
# GUS_USER_NAMES=(
#   "personal"     "John Doe"
#   "work-acme"    "John Doe"
#   "work-startup" "John"
#   "client-xyz"   "John Doe (Contractor)"
# )

# Example 2: Disable auto-switching (manual only)
# typeset -g GUS_AUTO_SWITCH=0

# Example 3: Mixed email formats
# typeset -gA GUS_EMAIL_TO_USER
# GUS_EMAIL_TO_USER=(
#   "personal@example.com"                    "github-personal"
#   "work@company.com"                        "github-work"
#   "12345678+username@users.noreply.github.com" "github-personal"
# )

# ============================================================================
# LOAD THE PLUGIN
# ============================================================================

# After configuration, source the plugin
# source ~/path/to/git-user-switch.plugin.zsh

# Example 2: Multiple users with different key types
# typeset -gA GUS_USER_KEYS
# GUS_USER_KEYS=(
#   "personal-github"   "~/.ssh/id_ed25519_personal"
#   "work-github"       "~/.ssh/id_rsa_work"
#   "freelance-github"  "~/.ssh/github_freelance_key"
#   "opensource"        "~/.ssh/id_ed25519"
# )

# Example 3: Corporate + Personal
# typeset -gA GUS_USER_KEYS
# GUS_USER_KEYS=(
#   "john-doe-personal"  "~/.ssh/id_rsa_personal"
#   "john-doe-acme-corp" "~/.ssh/id_rsa_acme"
#   "john-doe-client-x"  "~/.ssh/id_rsa_clientx"
# )

# Then load the plugin (choose one):

# Option A: Using Zi
# zi light dipodidae/zsh-plugin-git-user-switch

# Option B: Using Oh My Zsh
# Clone to: ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-user-switch
# Then add to plugins=(... git-user-switch)

# Option C: Manual source
# source ~/path/to/git-user-switch.plugin.zsh
