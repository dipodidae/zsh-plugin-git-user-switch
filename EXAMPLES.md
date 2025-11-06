# Example Usage

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
