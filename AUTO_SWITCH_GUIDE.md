# Auto-Switching Guide

This guide explains how to set up and use the automatic user switching feature in `git-user-switch`.

## What is Auto-Switching?

Auto-switching automatically changes your GitHub user (SSH key and gh CLI) when you navigate (`cd`) into different git repositories, based on the `user.email` configured in each repository.

## Quick Setup

### 1. Configure Email Mappings

Add this to your `.zshrc` **before** loading the plugin:

```zsh
# Map git emails to GitHub usernames
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "dipodidae@users.noreply.github.com"       "dipodidae"
  "spend-cloud-tom@users.noreply.github.com" "spend-cloud-tom"
)
```

### 2. Set Git Emails in Your Repositories

```bash
# Personal projects
cd ~/projects/personal-project
git config user.email "dipodidae@users.noreply.github.com"

# Work projects
cd ~/projects/work-project
git config user.email "spend-cloud-tom@users.noreply.github.com"
```

### 3. That's It!

Now when you `cd` between projects, the plugin automatically switches:

```bash
cd ~/projects/personal-project  # 🔄 Auto-switches to dipodidae
cd ~/projects/work-project      # 🔄 Auto-switches to spend-cloud-tom
```

## Advanced Setup

### Use Real Email Addresses

You can use your actual email addresses instead of GitHub's noreply format:

```zsh
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "personal@gmail.com"      "dipodidae"
  "tom@work-company.com"    "spend-cloud-tom"
)
```

### Multiple Emails for Same User

Map multiple emails to the same GitHub user:

```zsh
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "personal@gmail.com"                       "dipodidae"
  "12345+dipodidae@users.noreply.github.com" "dipodidae"
  "tom@work.com"                             "spend-cloud-tom"
  "tom@client-company.com"                   "spend-cloud-tom"
)
```

### Conditional Git Config (Pro Setup)

Set up directory-based git config for automatic email assignment:

**Create directory-specific configs:**

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

**Update your global `~/.gitconfig`:**

```ini
[includeIf "gitdir:~/projects/personal/"]
    path = ~/projects/personal/.gitconfig

[includeIf "gitdir:~/projects/work/"]
    path = ~/projects/work/.gitconfig
```

Now **all** repositories under `~/projects/personal/` automatically get the right email, and auto-switching works seamlessly!

## How It Works

1. **chpwd Hook**: The plugin registers a zsh hook that runs every time you change directories
2. **Git Detection**: It checks if the new directory is a git repository
3. **Email Lookup**: It reads `git config user.email`
4. **User Mapping**: It looks up the corresponding GitHub username in `GUS_EMAIL_TO_USER`
5. **Smart Switching**: If the user is different from the current one, it switches automatically
6. **Efficiency**: It tracks the current user to avoid redundant switches

## Configuration Options

### Enable/Disable Auto-Switching

```zsh
# Enable (default)
typeset -g GUS_AUTO_SWITCH=1

# Disable (manual switching only)
typeset -g GUS_AUTO_SWITCH=0
```

### Disable Temporarily

```bash
# Disable for current shell session
GUS_AUTO_SWITCH=0

# Re-enable
GUS_AUTO_SWITCH=1
```

## Troubleshooting

### Auto-switching not working?

**Check 1: Are you in a git repository?**
```bash
git status
```

**Check 2: Is user.email set?**
```bash
git config user.email
```

**Check 3: Is the email mapped?**
```bash
echo ${GUS_EMAIL_TO_USER[$(git config user.email)]}
```

**Check 4: Is auto-switching enabled?**
```bash
echo $GUS_AUTO_SWITCH
# Should output: 1
```

### See what's configured

```bash
# Show all email mappings
print -l "${(@kv)GUS_EMAIL_TO_USER}"

# Show all user/key mappings
print -l "${(@kv)GUS_USER_KEYS}"

# Show current user
echo $GUS_CURRENT_USER
```

## Best Practices

### 1. Use Directory-Based Organization

Organize your projects by account:

```
~/projects/
├── personal/       # dipodidae projects
│   ├── repo1/
│   └── repo2/
└── work/          # spend-cloud-tom projects
    ├── project1/
    └── project2/
```

Then use `includeIf` in your global gitconfig (see Advanced Setup above).

### 2. Set a Global Default

```bash
# Set your most-used account as global default
git config --global user.email "dipodidae@users.noreply.github.com"
git config --global user.name "dipodidae"
```

Then only override in specific repositories that need a different account.

### 3. Use Consistent Email Formats

Stick to one email format per account:
- ✅ Good: Always use `dipodidae@users.noreply.github.com`
- ❌ Confusing: Mix of `dipodidae@users.noreply.github.com`, `personal@gmail.com`, etc.

### 4. Document Your Setup

Keep a note of your email-to-user mappings somewhere:

```bash
# ~/.config/git-user-switch/mappings.txt
dipodidae@users.noreply.github.com       → dipodidae
spend-cloud-tom@users.noreply.github.com → spend-cloud-tom
```

## Example Workflows

### Workflow 1: Personal + Work

```zsh
# .zshrc configuration
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "personal-github"  "~/.ssh/id_ed25519_personal"
  "work-github"      "~/.ssh/id_ed25519_work"
)

typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "me@personal.com"    "personal-github"
  "me@company.com"     "work-github"
)
```

```bash
# Usage
cd ~/personal/my-project    # Auto-switches to personal-github
cd ~/work/company-project   # Auto-switches to work-github
```

### Workflow 2: Freelancer with Multiple Clients

```zsh
# .zshrc configuration
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "personal"      "~/.ssh/personal"
  "client-acme"   "~/.ssh/acme"
  "client-xyz"    "~/.ssh/xyz"
  "opensource"    "~/.ssh/opensource"
)

typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "me@personal.com"           "personal"
  "contractor@acme.com"       "client-acme"
  "freelance@xyzcorp.com"     "client-xyz"
  "contributor@opensource.io" "opensource"
)
```

```bash
# Usage - auto-switches based on project
cd ~/clients/acme/project     # Auto-switches to client-acme
cd ~/clients/xyz/website      # Auto-switches to client-xyz
cd ~/opensource/cool-lib      # Auto-switches to opensource
cd ~/personal/side-project    # Auto-switches to personal
```

### Workflow 3: Multiple GitHub Accounts + GitLab

```zsh
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "github-personal@email.com"  "github-personal"
  "github-work@email.com"      "github-work"
  "gitlab-work@email.com"      "github-work"  # Same keys for GitLab
)
```

## Tips

- **Feedback**: The plugin shows a message when auto-switching (🔄 icon)
- **Performance**: Auto-switching is very fast (only runs on `cd`)
- **Safety**: Auto-switching uses the same validation as manual switching
- **Flexibility**: You can still use `gus <user>` for manual switching anytime

## Disable Auto-Switching

If you prefer manual control:

```zsh
# In .zshrc before loading plugin
typeset -g GUS_AUTO_SWITCH=0

# Or unset the email mappings
unset GUS_EMAIL_TO_USER
```

Then use `gus <user>` manually whenever you need to switch.

## Further Reading

- [README.md](README.md) - Complete plugin documentation
- [QUICKSTART.md](QUICKSTART.md) - Fast setup guide
- [CONFIGURATION.md](CONFIGURATION.md) - Advanced configuration
- [EXAMPLES.md](EXAMPLES.md) - Usage examples

---

Enjoy seamless GitHub user switching! 🚀
