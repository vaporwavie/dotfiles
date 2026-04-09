# .files

Public release of my dotfiles setup.

## Install

```sh
./bootstrap.sh
```

This copies tracked dotfiles from the repo into `$HOME`, backing up any replaced paths into `~/.dotfiles-backup/<timestamp>`.
Tracked files inside directories like `.claude`, `.pi`, and `.codex` are installed individually, so unrelated local files are preserved.

Tracked Claude Code files under `.claude/` are intentionally limited to non-sensitive config and self-contained skills.

Useful options:

- `./bootstrap.sh --dry-run` to preview changes
- `TARGET_ROOT=/some/other/home ./bootstrap.sh` to install somewhere else

## Current Mac setup

- Mac Version: 14.5 Sonoma
- Shell: zsh 5.9 (x86_64-apple-darwin23.0)

## Content

The repo currently includes:

- oh-my-zsh (https://ohmyz.sh/)
- `gpp` and `gll` util functions for git
- `bun` and `fnm` completions
- `nvim` aliased as `vim`
- `bat` aliased as `cat` (https://github.com/sharkdp/bat)
- zsh-syntax-highlighting (https://github.com/zsh-users/zsh-syntax-highlighting)
- `.pi` agent settings and keyword-based model routing extension
- `.codex` non-sensitive durable config (`config.toml`, `AGENTS.md`, and rules)
- `.claude` Claude Code settings and a repo-safe frontend design skill
