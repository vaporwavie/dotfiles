eval $(/opt/homebrew/bin/brew shellenv zsh)

# Rust toolchain (moved out of .zshenv so it isn't sourced for every
# non-interactive `zsh -c …` invocation).
[[ -s "$HOME/.cargo/env" ]] && . "$HOME/.cargo/env"

# Added by OrbStack: command-line tools and integration
# This won't be added again if you remove it.
source ~/.orbstack/shell/init.zsh 2>/dev/null || :
