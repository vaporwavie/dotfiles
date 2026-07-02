# Intentionally minimal.
# `.zshenv` runs for *every* zsh invocation (including non-interactive shells
# spawned by editors, scripts, git hooks, etc.). Put login-only setup in
# `.zprofile` and interactive setup in `.zshrc`.

# Local-only secrets (not tracked by dotfiles); available to non-interactive shells.
[ -f "$HOME/.zshenv.local" ] && source "$HOME/.zshenv.local"
