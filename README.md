# zsh-plugin-git-user-switch

A simple zsh plugin to switch between multiple GitHub user accounts. It automatically updates both your SSH configuration and GitHub CLI (`gh`) authentication.

## Features

- 🔑 Automatically updates SSH config to use the correct identity file
- 👤 Switches `gh` CLI authentication to the specified user
- ✅ Validates user input and provides helpful error messages
- 🔄 Creates automatic backups of your SSH config before making changes
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
