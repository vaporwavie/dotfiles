# Claude Code config

This directory intentionally tracks only repo-safe Claude Code configuration:

- `settings.json`
- `CLAUDE.md` (a symlink into `.harness/CLAUDE.md`, which just points at the shared `.harness/AGENTS.md` ruleset)
- self-contained skills under `skills/`

Shared harness rules and the browser hooks live in `.harness/`, not here; `just-bash` and `agent-browser` are installed from npm by `bootstrap.sh`.

It intentionally excludes runtime and potentially sensitive Claude data such as sessions, projects, tasks, telemetry, caches, shell snapshots, and local plugin state.
