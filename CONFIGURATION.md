# Git User Switch - Configuration Examples

This file contains various configuration examples for different use cases.

## Example 1: Basic Two-User Setup (Default)

This matches your current setup:

```zsh
# In ~/.zshrc
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "dipodidae"       "~/.ssh/dipodidae"
  "spend-cloud-tom" "~/.ssh/spend-cloud-tom"
)

zi light dipodidae/zsh-plugin-git-user-switch
```

Usage:
```bash
gus dipodidae
gus spend-cloud-tom
```

---

## Example 2: Personal + Work Setup

```zsh
# In ~/.zshrc
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "personal"  "~/.ssh/id_ed25519_personal"
  "work"      "~/.ssh/id_rsa_work"
)

source ~/path/to/git-user-switch.plugin.zsh
```

Usage:
```bash
gus personal  # Switch to personal account
gus work      # Switch to work account
```

---

## Example 3: Multiple Clients (Freelancer Setup)

```zsh
# In ~/.zshrc
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "personal"    "~/.ssh/id_ed25519"
  "client-acme" "~/.ssh/id_rsa_acme"
  "client-beta" "~/.ssh/id_rsa_beta"
  "opensource"  "~/.ssh/id_ed25519_oss"
)

zi light dipodidae/zsh-plugin-git-user-switch
```

Usage:
```bash
gus personal
gus client-acme
gus client-beta
gus opensource
```

---

## Example 4: Company with Multiple GitHub Orgs

```zsh
# In ~/.zshrc
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "john-doe-personal"    "~/.ssh/personal_github"
  "john-doe-company"     "~/.ssh/company_github"
  "john-doe-enterprise"  "~/.ssh/enterprise_github"
)

source ~/plugins/git-user-switch/git-user-switch.plugin.zsh
```

Usage:
```bash
gus john-doe-personal
gus john-doe-company
gus john-doe-enterprise
```

---

## Example 5: Different Key Types

You can mix different SSH key types (RSA, Ed25519, ECDSA):

```zsh
# In ~/.zshrc
typeset -gA GUS_USER_KEYS
GUS_USER_KEYS=(
  "modern"   "~/.ssh/id_ed25519"          # Ed25519 (recommended)
  "legacy"   "~/.ssh/id_rsa"              # RSA
  "special"  "~/.ssh/id_ecdsa"            # ECDSA
  "custom"   "~/.ssh/my_special_key"      # Any name
)

zi light dipodidae/zsh-plugin-git-user-switch
```

---

## Example 6: No Configuration (Use Defaults)

If you don't set `GUS_USER_KEYS`, the plugin uses defaults:

```zsh
# In ~/.zshrc - just load the plugin
zi light dipodidae/zsh-plugin-git-user-switch
```

This will use:
- `dipodidae` → `~/.ssh/dipodidae`
- `spend-cloud-tom` → `~/.ssh/spend-cloud-tom`

---

## SSH Config Requirements

Your `~/.ssh/config` must have a `github.com` section with an `IdentityFile` line:

```
Host github.com
  HostName github.com
  User git
  IdentityFile ~/.ssh/your-default-key
  AddKeysToAgent yes
  IdentitiesOnly yes
```

The plugin will update the `IdentityFile` line when you run `gus <username>`.

---

## GitHub CLI Requirements

All users must be authenticated with `gh` CLI:

```bash
# Authenticate first user
gh auth login
# Follow prompts, login as user1

# Authenticate second user
gh auth login
# Follow prompts, login as user2

# Verify
gh auth status
```

---

## Troubleshooting

### Check your configuration
```bash
# After sourcing the plugin
print -l ${(kv)GUS_USER_KEYS}
```

### See available users
```bash
gus  # Run without arguments to see help
```

### Test SSH connection
```bash
ssh -T git@github.com
```

---

## Tips

1. **Use descriptive usernames**: Instead of `user1`, use `work` or `personal`
2. **Consistent naming**: Match your GitHub username for clarity
3. **Keep keys organized**: Use a consistent naming scheme for SSH keys
4. **Document your setup**: Add comments in your `.zshrc`
5. **Test before committing**: Always test the SSH connection after switching

---

## Advanced: Per-Project Auto-Switching

You can create a project-specific `.envrc` (with direnv):

```bash
# In project/.envrc
gus work
```

Or use a Git hook in your project:

```bash
# In project/.git/hooks/post-checkout
#!/bin/zsh
source ~/.zshrc
gus work
```
