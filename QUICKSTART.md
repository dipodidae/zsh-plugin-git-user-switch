# Quick Start Guide

Get up and running with `git-user-switch` in 5 minutes!

## Step 1: Prerequisites

Make sure you have:
- ✅ `gh` CLI installed and authenticated for your users
- ✅ SSH keys created for each GitHub account
- ✅ SSH config file at `~/.ssh/config`

### Install gh CLI (if needed)

```bash
# macOS
brew install gh

# Debian/Ubuntu
sudo apt install gh

# Or see: https://cli.github.com/
```

### Authenticate your GitHub accounts

```bash
# Authenticate first account
gh auth login
# Follow prompts, log in as dipodidae

# Authenticate second account
gh auth login
# Follow prompts, log in as spend-cloud-tom
```

## Step 2: Configure (Optional but Recommended)

Add this to your `.zshrc` **before** loading the plugin:

```zsh
# User to SSH key mapping
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
)

# Email to username mapping (for auto-switching)
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "dipodidae@users.noreply.github.com"       "dipodidae"
  "spend-cloud-tom@users.noreply.github.com" "spend-cloud-tom"
  # Or use your actual emails:
  # "your-personal@email.com"                "dipodidae"
  # "your-work@email.com"                    "spend-cloud-tom"
)

# Username to email mapping (for gus-appoint command)
typeset -gA GUS_USER_EMAILS
GUS_USER_EMAILS=(
  "dipodidae"       "dipodidae@users.noreply.github.com"
  "spend-cloud-tom" "spend-cloud-tom@users.noreply.github.com"
)

# Username to name mapping (for gus-appoint command)
typeset -gA GUS_USER_NAMES
GUS_USER_NAMES=(
  "dipodidae"       "dipodidae"
  "spend-cloud-tom" "Tom"
)

# Auto-switching is enabled by default, but you can disable it:
# typeset -g GUS_AUTO_SWITCH=0
```

**Note:** If you skip this step, the plugin uses sensible defaults matching the repository author's setup.

## Step 3: Install

Choose your preferred method:

### With Zi (recommended)
```zsh
zi light dipodidae/zsh-plugin-git-user-switch
```

### With Oh My Zsh
```bash
git clone https://github.com/dipodidae/zsh-plugin-git-user-switch.git \
  ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-user-switch

# Then add to plugins in .zshrc:
plugins=(... git-user-switch)
```

### Manual
```bash
git clone https://github.com/dipodidae/zsh-plugin-git-user-switch.git \
  ~/.zsh/plugins/git-user-switch

# Add to .zshrc:
source ~/.zsh/plugins/git-user-switch/git-user-switch.plugin.zsh
```

## Step 4: Set Up Your Git Repositories

You have two options to set up repositories:

### Option A: Use gus-appoint (Recommended - Easy!)

Navigate to your repository and appoint a user - it sets everything up automatically:

```bash
# Personal projects
cd ~/projects/my-personal-project
gus-appoint dipodidae

# Work projects
cd ~/projects/work-project
gus-appoint spend-cloud-tom
```

This automatically configures `user.name`, `user.email`, SSH keys, and gh CLI for that repository!

### Option B: Manual Configuration

Configure the email in each of your git repositories manually:

```bash
# Personal projects
cd ~/projects/my-personal-project
git config user.email "dipodidae@users.noreply.github.com"
git config user.name "dipodidae"

# Work projects
cd ~/projects/work-project
git config user.email "spend-cloud-tom@users.noreply.github.com"
git config user.name "Tom"
```

**Pro tip:** Set a global default for your most-used account:
```bash
git config --global user.email "your-main@email.com"
git config --global user.name "Your Name"
```

Then only override in specific repositories that need a different account.

## Step 5: Use It!

### Appointing Users to Repositories

Use `gus-appoint` to set up a user for a repository with one command:

```bash
cd ~/projects/my-new-repo
gus-appoint dipodidae
# Sets git config, SSH key, and gh CLI all at once!
```

### Auto-Switching (Just cd!)

Once configured, the plugin automatically switches when you navigate:

```bash
cd ~/projects/my-personal-project  # 🔄 Auto-switches to dipodidae
cd ~/projects/work-project         # 🔄 Auto-switches to spend-cloud-tom
```

### Manual Switching

You can also switch manually anytime:

```bash
# Switch to dipodidae
gus dipodidae

# Switch to spend-cloud-tom
gus spend-cloud-tom
```

## Step 6: Verify

Test that everything works:

```bash
# After switching (automatically or manually), test SSH
ssh -T git@github.com
# Should show: Hi <current-user>! You've successfully authenticated...

# Check gh CLI
gh auth status
# Should show the current authenticated user
```

You're all set! 🎉

## How Auto-Switching Works

1. When you `cd` into a directory, the plugin checks if it's a git repository
2. It reads the `git config user.email` value
3. It looks up the corresponding GitHub username in `GUS_EMAIL_TO_USER`
4. If a match is found and it's different from the current user, it auto-switches
5. SSH config and gh CLI are updated automatically

## Tips & Tricks

### Tip 1: Use Per-Directory Git Config

Create a `.gitconfig` in a parent directory:

```bash
# ~/projects/personal/.gitconfig
[user]
    email = dipodidae@users.noreply.github.com
    name = dipodidae

# ~/projects/work/.gitconfig
[user]
    email = spend-cloud-tom@users.noreply.github.com
    name = Tom
```

Then in your global `~/.gitconfig`:
```ini
[includeIf "gitdir:~/projects/personal/"]
    path = ~/projects/personal/.gitconfig

[includeIf "gitdir:~/projects/work/"]
    path = ~/projects/work/.gitconfig
```

Now all repos under `~/projects/personal/` auto-use your personal account!

### Tip 2: Disable Auto-Switching Temporarily

```bash
# Disable for current session
GUS_AUTO_SWITCH=0

# Or disable permanently in .zshrc before loading plugin
typeset -g GUS_AUTO_SWITCH=0
```

### Tip 3: See Current Configuration

```bash
# Show configured users
echo ${(k)GUS_USER_KEYS[@]}

# Show email mappings
echo ${(kv)GUS_EMAIL_TO_USER[@]}
```

## Common Issues

**"gh CLI not found"**
```bash
brew install gh  # macOS
# or visit: https://cli.github.com/
```

**"Failed to switch gh authentication"**
```bash
# Authenticate your accounts
gh auth login
```

**"SSH key not found"**
```bash
# Generate SSH keys if needed
ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/keyname

# Add to GitHub: Settings → SSH and GPG keys → New SSH key
cat ~/.ssh/keyname.pub
```

**Auto-switching not working**
```bash
# Check if you're in a git repository
git status

# Check the email in the repo
git config user.email

# Check if the email is mapped
echo ${GUS_EMAIL_TO_USER[$(git config user.email)]}
```

## Need More Help?

- [README](README.md) - Complete documentation
- [CONFIGURATION.md](CONFIGURATION.md) - Advanced configuration options
- [EXAMPLES.md](EXAMPLES.md) - More usage examples

Happy coding! 🚀
