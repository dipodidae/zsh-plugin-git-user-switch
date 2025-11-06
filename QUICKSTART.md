# Quick Start Guide

## 1. Set Up SSH Keys

Make sure you have SSH keys for both GitHub accounts:

```bash
# If you don't have keys yet, create them:
ssh-keygen -t rsa -b 4096 -C "your-dipodidae-email@example.com" -f ~/.ssh/id_rsa_dipodidae
ssh-keygen -t rsa -b 4096 -C "your-spend-cloud-tom-email@example.com" -f ~/.ssh/id_rsa_spend_cloud_tom

# Add the public keys to GitHub:
# 1. Copy your public key:
cat ~/.ssh/id_rsa_dipodidae.pub
# 2. Go to GitHub.com → Settings → SSH and GPG keys → New SSH key
# 3. Paste and save
# Repeat for the other account
```

## 2. Set Up SSH Config

Create or edit `~/.ssh/config`:

```bash
# Copy the example config:
mkdir -p ~/.ssh
cat > ~/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_dipodidae
  AddKeysToAgent yes
  IdentitiesOnly yes
EOF

# Secure your SSH directory:
chmod 700 ~/.ssh
chmod 600 ~/.ssh/config
chmod 600 ~/.ssh/id_rsa_*
```

## 3. Authenticate GitHub CLI

```bash
# Install gh CLI if needed (macOS):
brew install gh

# Or on Debian/Ubuntu:
# sudo apt install gh

# Authenticate both accounts:
gh auth login
# Choose GitHub.com, HTTPS, authenticate via browser
# Log in as dipodidae

# Then authenticate the second account:
gh auth login
# Log in as spend-cloud-tom
```

## 4. Install the Plugin

### Option A: Manual (for testing)

```bash
# Just source it in your current shell:
source ~/clones/zsh-plugin-git-user-switch/git-user-switch.plugin.zsh
```

### Option B: Add to .zshrc (permanent)

```bash
# Add this line to your ~/.zshrc:
echo 'source ~/clones/zsh-plugin-git-user-switch/git-user-switch.plugin.zsh' >> ~/.zshrc

# Reload your shell:
source ~/.zshrc
```

### Option C: Use a plugin manager

See README.md for instructions on using Zi, Oh My Zsh, or zplug.

## 5. Use the Plugin

```bash
# Switch to dipodidae:
gus dipodidae

# Switch to spend-cloud-tom:
gus spend-cloud-tom

# Check current gh user:
gh auth status
```

## 6. Verify It Works

```bash
# Test SSH connection:
ssh -T git@github.com
# Should show: Hi <current-user>! You've successfully authenticated...

# Test gh CLI:
gh auth status
# Should show the current authenticated user

# Clone a repo to test:
git clone git@github.com:dipodidae/some-repo.git
```

## Customization

If your SSH keys have different names, edit `git-user-switch.plugin.zsh`:

```zsh
case "${username}" in
  dipodidae)
    ssh_key_file="${HOME}/.ssh/id_ed25519_dipodidae"  # Your actual key name
    ;;
  spend-cloud-tom)
    ssh_key_file="${HOME}/.ssh/id_ed25519_work"  # Your actual key name
    ;;
esac
```

## Troubleshooting

### Issue: "Permission denied (publickey)"

```bash
# Make sure your key has correct permissions:
chmod 600 ~/.ssh/id_rsa_dipodidae
chmod 600 ~/.ssh/id_rsa_spend_cloud_tom

# Test which key is being used:
ssh -vT git@github.com 2>&1 | grep "identity file"
```

### Issue: "Failed to switch gh authentication"

```bash
# List authenticated accounts:
gh auth status

# Re-authenticate if needed:
gh auth login
```

### Issue: Plugin command not found

```bash
# Make sure the plugin is sourced:
source ~/clones/zsh-plugin-git-user-switch/git-user-switch.plugin.zsh

# Check if function exists:
type gus
```

## Next Steps

1. Add the plugin to your favorite plugin manager
2. Customize SSH key paths if needed
3. Consider publishing to GitHub for others to use!

Happy coding! 🚀
