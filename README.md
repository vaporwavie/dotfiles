# .files

Public release of my dotfiles setup.

## Install

```sh
./bootstrap.sh
```

This copies tracked dotfiles from the repo into `$HOME`, backing up any replaced paths into `~/.dotfiles-backup/<timestamp>`.
Tracked files inside directories like `.harness`, `.claude`, `.codex`, and `.local` are installed individually, so unrelated local files are preserved.
Curated macOS app configs under `Library/Application Support/` (e.g. Ghostty) are installed the same way, despite not being dot-prefixed.

It also installs the agent CLIs (`agent-browser`, `just-bash`) from their upstream npm packages, so the repo never vendors a copy of them.

Tracked Claude Code files under `.claude/` are intentionally limited to non-sensitive config and self-contained skills.

Useful options:

- `./bootstrap.sh --dry-run` to preview changes
- `./bootstrap.sh --no-tools` to skip the agent CLI installs
- `TARGET_ROOT=/some/other/home ./bootstrap.sh` to install somewhere else

## Current Mac setup

- Mac Version: 14.5 Sonoma
- Shell: zsh 5.9 (x86_64-apple-darwin23.0)

## Content

The repo currently includes:

- Hand-rolled zsh config (no oh-my-zsh) — `.zshrc`, `.zshenv`, `.zprofile`
  - Cached `compinit` with weekly audit + `zcompile`d dump
  - Async git prompt via vendored [zsh-async](https://github.com/mafredri/zsh-async) at `.zsh/async.zsh` (branch synchronous, dirty marker in background worker)
  - Lazy-loaded `fnm` (node/npm/npx/pnpm/yarn/corepack stubs swap themselves in on first use)
  - `.zshenv` intentionally empty; cargo/brew/orbstack live in `.zprofile`
- `gpp`, `gll`, `gds`, `gmm` util functions for git
- `bun` and `fnm` completions
- `nvim` aliased as `vim`
- [vim-with-a-hat](https://github.com/vaporwavie/vim-with-a-hat) wiring: Ghostty binds `cmd+shift+e` / `cmd+shift+b` to dump the screen/scrollback to a temp file, and the `_vh_accept_line` zsh hook opens that path in `vh` (a native GUI window) instead of running it
- Ghostty config at `Library/Application Support/com.mitchellh.ghostty/config`, plus the custom `grokday`/`groknight` themes it references under `…/themes/`
- `bat` aliased as `cat` (https://github.com/sharkdp/bat)
- `.pi` agent settings and keyword-based model routing extension
- `.harness` centralized agent ruleset shared by every harness: `AGENTS.md` is the single source of truth, `CLAUDE.md` just points at it, and the browser-guard `hooks/` live alongside
- agent CLIs are installed from upstream by `bootstrap.sh`, not vendored: [`agent-browser`](https://github.com/vercel-labs/agent-browser) and [`just-bash`](https://github.com/vercel-labs/just-bash)
- `.codex` non-sensitive durable config (`config.toml` and rules); `AGENTS.md` is a symlink into `.harness`
- `.claude` Claude Code settings and a repo-safe frontend design skill; `CLAUDE.md` is a symlink into `.harness`
- `.local/bin/claude-p-watch` agent helper script
