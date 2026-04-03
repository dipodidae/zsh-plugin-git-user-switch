# zsh-plugin-git-user-switch

Safe-by-default GitHub identity switching for zsh.

The plugin coordinates three pieces of state:

- repository git identity
- GitHub SSH routing
- optional GitHub CLI account switching

The default design is `Safe & Predictable`:

- no global SSH mutation during normal use
- repository remotes are rewritten to per-user SSH host aliases such as `github-work`
- current state is derived from git config, remotes, and `gh auth status`

An opt-in `magic` mode is still available if you want the older global `Host github.com` rewrite behavior.

## Philosophy

Primary mode: `safe`

- deterministic, repo-scoped behavior
- no hidden writes to `~/.ssh/config`
- easy to inspect with `gus status` and `gus doctor`

Secondary mode: `magic`

- explicit opt-in with `GUS_MODE=magic`
- rewrites the `Host github.com` block atomically
- creates timestamped backups like `~/.ssh/config.bak.20260331153000`

## Installation

Source the plugin from your `.zshrc`.

```zsh
source /path/to/zsh-plugin-git-user-switch/git-user-switch.plugin.zsh
```

## Configuration

The plugin now uses one source of truth: `GUS_USERS`.

Default config path:

```text
${XDG_CONFIG_HOME:-$HOME/.config}/git-user-switch/config.zsh
```

Example:

```zsh
typeset -gA GUS_USERS
GUS_USERS=(
  "personal:key" "~/.ssh/personal"
  "personal:email" "personal@example.com"
  "personal:name" "Personal User"
  "personal:host_alias" "github-personal"
  "personal:gh_user" "personal-gh"

  "work:key" "~/.ssh/work"
  "work:email" "work@example.com"
  "work:name" "Work User"
  "work:host_alias" "github-work"
  "work:gh_user" "work-gh"
)
```

Fields:

- `user:key`: private SSH key path
- `user:email`: repo `git config user.email`
- `user:name`: repo `git config user.name`
- `user:host_alias`: SSH alias used in safe mode remotes
- `user:gh_user`: `gh` account name for `gh auth switch --user`

Optional environment flags before loading the plugin:

```zsh
export GUS_MODE=safe
export GUS_AUTO_SWITCH=1
export GUS_VERBOSE=0
export GUS_ENABLE_GH_SWITCH=1
export GUS_CONFIG_FILE="$HOME/.config/git-user-switch/config.zsh"
```

Legacy associative arrays are still imported for compatibility, but `GUS_USERS` is the target format.

## Safe-Mode SSH Setup

Add one alias per identity to `~/.ssh/config`:

```sshconfig
Host github-personal
  HostName github.com
  User git
  IdentityFile ~/.ssh/personal

Host github-work
  HostName github.com
  User git
  IdentityFile ~/.ssh/work
```

In safe mode, `gus` rewrites repository remotes from `git@github.com:owner/repo.git` to `git@github-work:owner/repo.git` or similar.

## Commands

```bash
gus switch <user>
gus appoint <user>
gus status
gus list
gus doctor
gus help
```

Compatibility shims still exist:

```bash
gus <user>
gus-appoint <user>
```

## Usage

Switch a repository to a configured identity without changing repo git config:

```bash
gus switch work
```

Appoint a user to the current repository:

```bash
gus appoint work
```

Inspect state:

```bash
gus status
gus doctor
```

## Auto-Switching

Auto-switch is enabled by default and runs on directory change.

Behavior:

- reads repo-local `user.email`
- maps it to a configured user
- applies the same switching pipeline quietly
- respects `GUS_AUTO_SWITCH=0`
- can be temporarily disabled with `gus lock` and re-enabled with `gus unlock`

## Current Implementation Status

Implemented in this refactor pass:

- unified `gus` subcommands
- safe-mode remote rewriting
- opt-in magic SSH mode with backups
- `gus status`, `gus list`, and `gus doctor`
- compatibility import for legacy config arrays
- behavior-focused zsh tests for safe and magic modes

The remaining guide files in the repo still need to be rewritten to match the new model.
