# Aliases
alias cat=bat

# Pull from the remote branch and rebase
function gll() {
  git pull --rebase origin $(git_current_branch)
}

# Push to the remote branch
function gpp() {
  git push origin $(git_current_branch)
}

# bun completions
[ -s "/Users/luiznickel/.bun/_bun" ] && source "/Users/luiznickel/.bun/_bun"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# fnm
FNM_PATH="/Users/luiznickel/Library/Application Support/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/Users/luiznickel/Library/Application Support/fnm:$PATH"
  eval "`fnm env`"
fi
