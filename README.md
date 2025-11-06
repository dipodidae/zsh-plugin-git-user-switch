# zsh-plugin-git-user-switch

A simple zsh plugin to switch between multiple GitHub user accounts. It automatically updates both your SSH configuration and GitHub CLI (`gh`) authentication.

## Features

- 🔑 Automatically updates SSH config to use the correct identity file
- 👤 Switches `gh` CLI authentication to the specified user
- 🔄 **Auto-switches based on git repository config** (when you `cd` into a directory)
- 📝 **Appoint users to repositories** with full git config setup
- ⚙️ Fully configurable user/key mappings
- ✅ Validates user input and provides helpful error messages
- 💾 Creates automatic backups of your SSH config before making changes
- 📦 Follows the [Zsh Plugin Standard](https://z-shell.pages.dev/docs/zsh-plugin-standard)

## Prerequisites

1. **GitHub CLI (`gh`)** installed and authenticated for both users
   ```bash
   gh auth login
   ```

2. **SSH keys** set up for both users at:
   - `~/.ssh/id_rsa_dipodidae` (or your preferred key name)
   - `~/.ssh/id_rsa_spend_cloud_tom` (or your preferred key name)

3. **SSH config** (`~/.ssh/config`) with a GitHub section:
   ```ssh
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_rsa_dipodidae
   ```

## Configuration

The plugin uses a configurable mapping between GitHub usernames and SSH key paths. You can customize this in your `.zshrc` **before** loading the plugin.

### Default Configuration

If you don't provide a custom configuration, the plugin uses these defaults:

```zsh
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
)
```

**Note:** These paths match the repository author's setup. You should customize them to match your own SSH key locations.

### Custom Configuration

To use your own user/key mappings, add this to your `.zshrc` **before** the plugin is loaded:

```zsh
# Define your custom user-to-key mapping
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
  "another-user"    "~/.ssh/another_user_key"
)

# Define email-to-username mapping for auto-switching
typeset -gA GUS_EMAIL_TO_USER
GUS_EMAIL_TO_USER=(
  "dipodidae@users.noreply.github.com"       "dipodidae"
  "tom@work.com"                             "spend-cloud-tom"
  "another@example.com"                      "another-user"
)

# Optional: Disable auto-switching (enabled by default)
# typeset -g GUS_AUTO_SWITCH=0

# Then load the plugin (example with Zi)
zi light dipodidae/zsh-plugin-git-user-switch
```

**Configuration Options:**
- `GUS_USER_KEYS`: Maps GitHub username → SSH key path
- `GUS_EMAIL_TO_USER`: Maps git user.email → GitHub username (for auto-switching)
- `GUS_USER_EMAILS`: Maps GitHub username → git user.email (for appointing users)
- `GUS_USER_NAMES`: Maps GitHub username → git user.name (for appointing users)
- `GUS_AUTO_SWITCH`: Enable/disable auto-switching (1 = enabled, 0 = disabled, default: 1)

**Note:** The mapping format is:
- Key: GitHub username (must match your `gh` CLI authenticated username)
- Value: Path to SSH private key (can use `~` for home directory)

## Installation

### Using [Zi](https://github.com/z-shell/zi)

```zsh
zi light dipodidae/zsh-plugin-git-user-switch
```

### Using [Oh My Zsh](https://ohmyz.sh/)

1. Clone the repository:
   ```bash
   git clone https://github.com/dipodidae/zsh-plugin-git-user-switch.git \
     ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/git-user-switch
   ```

2. Add to your `.zshrc`:
   ```zsh
   plugins=(... git-user-switch)
   ```

### Using [zplug](https://github.com/zplug/zplug)

```zsh
zplug "dipodidae/zsh-plugin-git-user-switch"
```

### Manual Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/dipodidae/zsh-plugin-git-user-switch.git \
     ~/.zsh/plugins/git-user-switch
   ```

2. Source the plugin in your `.zshrc`:
   ```zsh
   source ~/.zsh/plugins/git-user-switch/git-user-switch.plugin.zsh
   ```

## Usage

### Appointing a User to a Repository

Use the `gus-appoint` command to set up a user for a specific repository with all necessary git config:

```bash
# Navigate to your repository
cd ~/projects/my-work-repo

# Appoint a user to this repository
gus-appoint spend-cloud-tom
```

This command will:
1. Set `git config user.name` and `user.email` for the repository
2. Update your `~/.ssh/config` to use the correct SSH key
3. Switch your `gh` CLI authentication to the specified user

Perfect for setting up new repositories or switching ownership of existing ones!

**For detailed information, see the [Repository Appointment Guide](APPOINT-GUIDE.md).**

### Manual Switching

Switch between users with the `gus` command:

```bash
# Switch to dipodidae account
gus dipodidae

# Switch to spend-cloud-tom account
gus spend-cloud-tom
```

The plugin will:
1. Update your `~/.ssh/config` to use the correct SSH key
2. Switch your `gh` CLI authentication to the specified user
3. Create a backup of your SSH config at `~/.ssh/config.bak`

### Automatic Switching

The plugin automatically switches users when you navigate to a git repository, based on the `user.email` in the git config:

```bash
# Set git email in your personal project
cd ~/projects/personal-repo
git config user.email "dipodidae@users.noreply.github.com"

# Set git email in your work project
cd ~/projects/work-repo
git config user.email "tom@work.com"

# Now when you cd between them, the plugin auto-switches!
cd ~/projects/personal-repo  # 🔄 Auto-switches to dipodidae
cd ~/projects/work-project         # 🔄 Auto-switches to spend-cloud-tom
```

## Commands Reference

The plugin provides the following commands:

### `gus help`
Display brief usage information for all commands.

```bash
gus help        # Show help
gus --help      # Also works
gus -h          # Also works
```

### `gus <username>`
Switch to a different GitHub user globally (SSH config and gh CLI).

```bash
gus dipodidae        # Switch to dipodidae
gus spend-cloud-tom  # Switch to spend-cloud-tom
```

**What it does:**
- Updates SSH config to use the user's SSH key
- Switches gh CLI authentication
- Updates internal user tracking

### `gus-appoint <username>`
Appoint a user to the current git repository with complete configuration.

```bash
cd ~/projects/my-repo
gus-appoint dipodidae  # Set up repository for dipodidae
```

**What it does:**
- Sets `git config user.name` for the repository
- Sets `git config user.email` for the repository
- Updates SSH config to use the user's SSH key
- Switches gh CLI authentication
- Updates internal user tracking

**Requires:** Must be run inside a git repository

See [APPOINT-GUIDE.md](APPOINT-GUIDE.md) for detailed usage.

## Configuration

By default, the plugin expects SSH keys at:
```

**How it works:**
1. When you `cd` into a directory, the plugin checks if it's a git repository
2. It reads the `git config user.email` value
3. It looks up the corresponding GitHub username in `GUS_EMAIL_TO_USER`
4. If a match is found and it's different from the current user, it auto-switches

**To disable auto-switching:**
```zsh
# In your .zshrc before loading the plugin
typeset -g GUS_AUTO_SWITCH=0
```

## Configuration

By default, the plugin expects SSH keys at:
- `~/.ssh/id_rsa_dipodidae`
- `~/.ssh/id_rsa_spend_cloud_tom`

If your keys are located elsewhere, you can modify the `.gus_update_ssh_config` function in `git-user-switch.plugin.zsh`:

```zsh
case "${username}" in
  dipodidae)
    ssh_key_file="${HOME}/.ssh/your_custom_key_name"
    ;;
  spend-cloud-tom)
    ssh_key_file="${HOME}/.ssh/another_key_name"
    ;;
esac
```

## Troubleshooting

### "gh CLI not found"
Install the GitHub CLI: https://cli.github.com/

### "Failed to switch gh authentication"
Make sure both users are authenticated:
```bash
gh auth login
```

### "SSH key not found"
Ensure your SSH keys exist at the expected locations and have the correct permissions:
```bash
chmod 600 ~/.ssh/id_rsa_*
```

### "SSH config not found"
Create a `~/.ssh/config` file with a GitHub section:
```bash
mkdir -p ~/.ssh
cat >> ~/.ssh/config << 'EOF'
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/id_rsa_dipodidae
EOF
```

## Development

This plugin follows:
- [Zsh Plugin Standard](https://z-shell.pages.dev/docs/zsh-plugin-standard)
- [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html)

### Plugin Structure

```
.
├── git-user-switch.plugin.zsh  # Main plugin file
└── README.md                    # This file
```

### Unloading

The plugin provides an unload function that can be called by plugin managers:
```zsh
git_user_switch_plugin_unload
```

## License

MIT License - feel free to use and modify as needed.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## Author

Tom (@dipodidae)
