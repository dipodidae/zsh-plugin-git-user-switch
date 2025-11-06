# Examples

## Basic Usage

### Configuration in .zshrc

```zsh
# Example 1: Using default configuration
# (Keys at ~/.ssh/id_rsa_dipodidae and ~/.ssh/id_rsa_spend_cloud_tom)
zi light dipodidae/zsh-plugin-git-user-switch

# Example 2: Custom key locations
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
)
zi light dipodidae/zsh-plugin-git-user-switch

# Example 3: Multiple users with different key types
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "personal"   "~/.ssh/id_ed25519_personal"
  "work"       "~/.ssh/id_rsa_work"
  "freelance"  "~/.ssh/github_freelance"
)
source ~/path/to/git-user-switch.plugin.zsh
```

## Switching Users

## Getting Help

```console
$ gus help
Git User Switch - Manage multiple GitHub accounts

COMMANDS:
  gus <user>          Switch to user globally (SSH + gh CLI)
  gus-appoint <user>  Appoint user to current repo (git config + SSH + gh CLI)
  gus help            Show this help

EXAMPLES:
  gus dipodidae                    # Switch globally to dipodidae
  cd ~/work-repo && gus-appoint work-user   # Set up repo for work-user

AVAILABLE USERS:
  dipodidae spend-cloud-tom

CONFIGURATION:
  Configure in ~/.zshrc before loading plugin:
    typeset -gA GUS_USER_KEYS       # user → SSH key path
    typeset -gA GUS_USER_EMAILS     # user → git email (for gus-appoint)
    typeset -gA GUS_USER_NAMES      # user → git name (for gus-appoint)
    typeset -gA GUS_EMAIL_TO_USER   # email → user (for auto-switch)

DOCS: See README.md, QUICKSTART.md, APPOINT-GUIDE.md
```

## Appointing a User to a Repository

```console
$ cd ~/projects/work-repo

$ gus-appoint spend-cloud-tom
Appointing spend-cloud-tom to this repository...

Setting git config for this repository:
  user.name  = Tom
  user.email = spend-cloud-tom@users.noreply.github.com

✓ Updated SSH config to use: /home/tom/.ssh/spend-cloud-tom
✓ Switched gh CLI to user: spend-cloud-tom

✓ Successfully appointed spend-cloud-tom to this repository
  Git config, SSH key, and gh CLI are now configured for spend-cloud-tom.

Repository location: /home/tom/projects/work-repo
```

Now when you commit in this repository:
```console
$ git commit -m "Initial commit"
[main abc1234] Initial commit
 Author: Tom <spend-cloud-tom@users.noreply.github.com>
```

And auto-switching will work when you navigate to this repository:
```console
$ cd ~/projects/personal-repo
🔄 Auto-switching to GitHub user: dipodidae (based on git config)

$ cd ~/projects/work-repo
🔄 Auto-switching to GitHub user: spend-cloud-tom (based on git config)
```

## Switching to dipodidae

```console
$ gus dipodidae
Switching to GitHub user: dipodidae
✓ Updated SSH config to use: /home/tom/.ssh/id_rsa_dipodidae
✓ Switched gh CLI to user: dipodidae

✓ Successfully switched to dipodidae
  SSH key and gh CLI are now configured for this user.
```

## Switching to spend-cloud-tom

```console
$ gus spend-cloud-tom
Switching to GitHub user: spend-cloud-tom
✓ Updated SSH config to use: /home/tom/.ssh/id_rsa_spend_cloud_tom
✓ Switched gh CLI to user: spend-cloud-tom

✓ Successfully switched to spend-cloud-tom
  SSH key and gh CLI are now configured for this user.
```

## Error: Invalid username

```console
$ gus invalid-user
[git-user-switch]: Invalid username: invalid-user
[git-user-switch]: Valid usernames: dipodidae spend-cloud-tom
```

## Error: Missing argument

```console
$ gus
[git-user-switch]: Usage: gus <username>
[git-user-switch]: Valid usernames: dipodidae spend-cloud-tom
```

## Verifying the switch

```console
$ gus dipodidae
Switching to GitHub user: dipodidae
✓ Updated SSH config to use: /home/tom/.ssh/id_rsa_dipodidae
✓ Switched gh CLI to user: dipodidae

✓ Successfully switched to dipodidae
  SSH key and gh CLI are now configured for this user.

$ gh auth status
github.com
  ✓ Logged in to github.com as dipodidae (oauth_token)
  ✓ Git operations for github.com configured to use https protocol.
  ✓ Token: *******************

$ ssh -T git@github.com
Hi dipodidae! You've successfully authenticated, but GitHub does not provide shell access.
```

## What happens behind the scenes?

1. **SSH Config Update**: The plugin modifies your `~/.ssh/config`:
   ```diff
   Host github.com
     HostName github.com
     User git
   - IdentityFile ~/.ssh/id_rsa_spend_cloud_tom
   + IdentityFile ~/.ssh/id_rsa_dipodidae
     AddKeysToAgent yes
     IdentitiesOnly yes
   ```

2. **Backup Created**: A backup is automatically created at `~/.ssh/config.bak`

3. **GH CLI Switch**: The plugin runs:
   ```bash
   gh auth switch --user dipodidae
   ```

All in one simple command: `gus dipodidae` 🎉
