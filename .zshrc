# Oh My Zsh + Plugins
export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

plugins=(git)

source $ZSH/oh-my-zsh.sh

# Aliases
alias cat=bat
alias vim=nvim

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
eval "$(fnm env --use-on-cd)"
FNM_PATH="/Users/luiz.nickel/Library/Application Support/fnm"
if [ -d "$FNM_PATH" ]; then
  export PATH="/Users/luiz.nickel/Library/Application Support/fnm:$PATH"
fi

