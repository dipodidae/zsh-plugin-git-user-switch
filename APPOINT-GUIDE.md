# Repository User Appointment Guide

The `gus-appoint` command makes it easy to set up a complete user identity for a specific git repository. It configures all necessary settings in one command.

## What Does `gus-appoint` Do?

When you run `gus-appoint <username>`, the plugin:

1. ✅ Sets `git config user.name` for the repository
2. ✅ Sets `git config user.email` for the repository  
3. ✅ Updates SSH config to use the correct identity file
4. ✅ Switches `gh` CLI authentication to the specified user
5. ✅ Updates internal tracking for auto-switching

## Usage

```bash
# Navigate to your repository
cd ~/projects/my-work-repo

# Appoint a user
gus-appoint spend-cloud-tom
```

## Complete Example

```console
$ cd ~/projects/new-work-project

$ gus-appoint spend-cloud-tom
Appointing spend-cloud-tom to this repository...

Setting git config for this repository:
  user.name  = Tom
  user.email = spend-cloud-tom@users.noreply.github.com

✓ Updated SSH config to use: /home/tom/.ssh/spend-cloud-tom
✓ Switched gh CLI to user: spend-cloud-tom

✓ Successfully appointed spend-cloud-tom to this repository
  Git config, SSH key, and gh CLI are now configured for spend-cloud-tom.

Repository location: /home/tom/projects/new-work-project
```

## Verify the Configuration

After appointing a user, you can verify the settings:

```bash
# Check git config
git config user.name
# Output: Tom

git config user.email
# Output: spend-cloud-tom@users.noreply.github.com

# Test SSH connection
ssh -T git@github.com
# Output: Hi spend-cloud-tom! You've successfully authenticated...

# Check gh CLI
gh auth status
# Shows: Logged in to github.com as spend-cloud-tom
```

## When to Use `gus-appoint`

### Perfect for:

- 🆕 **New repositories**: Set up user identity when creating a new repo
- 🔄 **Changing ownership**: Transfer a repository to a different account
- 🛠️ **Quick setup**: Configure everything in one command instead of multiple git configs
- 👥 **Team onboarding**: Help team members set up their repos quickly

### Example Scenarios:

**Scenario 1: Starting a new work project**
```bash
mkdir ~/projects/company-api
cd ~/projects/company-api
git init
gus-appoint work-account
# Now ready to commit with work identity!
```

**Scenario 2: Forked an open-source project**
```bash
cd ~/projects/open-source/some-project
gus-appoint personal-account
# Now commits use your personal identity
```

**Scenario 3: Cloned a work repository**
```bash
cd ~/projects/work/client-project
gus-appoint client-account
# All commits will use client account identity
```

## Configuration Required

To use `gus-appoint`, you need to configure the following in your `.zshrc` **before** loading the plugin:

```zsh
# Username to email mapping (required for gus-appoint)
typeset -gA GUS_USER_EMAILS
GUS_USER_EMAILS=(
  "dipodidae"       "dipodidae@users.noreply.github.com"
  "spend-cloud-tom" "spend-cloud-tom@users.noreply.github.com"
  "work-account"    "you@company.com"
  "personal"        "personal@example.com"
)

# Username to name mapping (optional, defaults to username)
typeset -gA GUS_USER_NAMES
GUS_USER_NAMES=(
  "dipodidae"       "dipodidae"
  "spend-cloud-tom" "Tom"
  "work-account"    "Your Full Name"
  "personal"        "Your Name"
)

# Username to SSH key mapping (required)
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
  "work-account"    "~/.ssh/id_rsa_work"
  "personal"        "~/.ssh/id_ed25519_personal"
)
```

### Default Configuration

If you don't configure `GUS_USER_EMAILS` and `GUS_USER_NAMES`, the plugin uses these defaults:

```zsh
GUS_USER_EMAILS=(
  "dipodidae"       "dipodidae@users.noreply.github.com"
  "spend-cloud-tom" "spend-cloud-tom@users.noreply.github.com"
)

GUS_USER_NAMES=(
  "dipodidae"       "dipodidae"
  "spend-cloud-tom" "Tom"
)
```

## Error Handling

### Not in a git repository
```console
$ gus-appoint dipodidae
[git-user-switch]: Not in a git repository
[git-user-switch]: Please navigate to a git repository first
```

**Solution**: Navigate to a git repository or initialize one with `git init`

### Invalid username
```console
$ gus-appoint nonexistent-user
[git-user-switch]: Invalid username: nonexistent-user
[git-user-switch]: Available users: dipodidae spend-cloud-tom
```

**Solution**: Use one of the available configured users

### Email not configured
```console
$ gus-appoint some-user
[git-user-switch]: No email configured for user: some-user
[git-user-switch]: Please add to GUS_USER_EMAILS in your .zshrc
```

**Solution**: Add the user to `GUS_USER_EMAILS` configuration

## Comparison: Manual vs `gus-appoint`

### Manual Setup (5 commands)
```bash
cd ~/projects/my-repo
git config user.name "Tom"
git config user.email "spend-cloud-tom@users.noreply.github.com"
gus spend-cloud-tom
# Then verify SSH and gh...
```

### With `gus-appoint` (1 command)
```bash
cd ~/projects/my-repo
gus-appoint spend-cloud-tom
# Everything configured! ✨
```

## Benefits of Auto-Switching After Appointing

After using `gus-appoint`, the plugin will automatically switch to the correct user when you navigate to this repository:

```bash
# First time setup
cd ~/projects/work-repo
gus-appoint spend-cloud-tom

# Later, when you come back...
cd ~/projects/personal-repo
# 🔄 Auto-switches to dipodidae

cd ~/projects/work-repo
# 🔄 Auto-switches to spend-cloud-tom (no manual command needed!)
```

## Advanced: Batch Appointing

You can appoint users to multiple repositories using a script:

```bash
#!/usr/bin/env zsh

# Appoint work account to all work repositories
for repo in ~/projects/work/*; do
  if [[ -d "$repo/.git" ]]; then
    echo "Appointing to: $repo"
    (cd "$repo" && gus-appoint work-account)
  fi
done

# Appoint personal account to all personal repositories
for repo in ~/projects/personal/*; do
  if [[ -d "$repo/.git" ]]; then
    echo "Appointing to: $repo"
    (cd "$repo" && gus-appoint personal)
  fi
done
```

## Tips

1. **Run after cloning**: Make it a habit to run `gus-appoint` right after cloning a new repository
2. **Use with aliases**: Create shell aliases for common setups:
   ```zsh
   alias gus-work='gus-appoint spend-cloud-tom'
   alias gus-personal='gus-appoint dipodidae'
   ```
3. **Combine with directory configs**: Use with git's `includeIf` for automatic defaults per directory
4. **Check before committing**: Run `git config user.email` to verify the identity before important commits

## See Also

- [README.md](README.md) - Complete plugin documentation
- [QUICKSTART.md](QUICKSTART.md) - Quick start guide
- [EXAMPLES.md](EXAMPLES.md) - More usage examples
- [CONFIGURATION.md](CONFIGURATION.md) - Advanced configuration options
- [AUTO_SWITCH_GUIDE.md](AUTO_SWITCH_GUIDE.md) - Auto-switching documentation

## Summary

The `gus-appoint` command is the easiest way to set up a complete user identity for a git repository. It saves time, reduces errors, and ensures all necessary configurations are in place for commits, pushes, and CLI operations.

**One command. Complete setup. Happy coding! 🚀**
