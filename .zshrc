typeset -U path fpath

export BUN_INSTALL="$HOME/.bun"

path=(
  $HOME/.local/bin
  $HOME/.opencode/bin
  $HOME/.amp/bin
  $HOME/.deno/bin
  $BUN_INSTALL/bin
  $HOME/go/bin
  $path
)

setopt auto_cd auto_pushd pushdminus pushd_ignore_dups
setopt auto_menu complete_in_word always_to_end
setopt extended_history share_history hist_ignore_dups hist_ignore_space
setopt hist_verify hist_expire_dups_first
setopt multios long_list_jobs interactivecomments prompt_subst

HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=10000

zmodload -i zsh/complist
WORDCHARS=''

fpath=($HOME/.zsh/completions $fpath)

autoload -Uz compinit
() {
  setopt local_options extendedglob
  if [[ -n $HOME/.zcompdump(#qN.mh+24) ]] || [[ ! -f $HOME/.zcompdump ]]; then
    compinit
  else
    compinit -C
  fi
}

zstyle ':completion:*:*:*:*:*' menu select
zstyle ':completion:*' matcher-list 'm:{[:lower:][:upper:]}={[:upper:][:lower:]}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' list-colors ''
zstyle ':completion:*:*:kill:*:processes' list-colors '=(#b) #([0-9]#) ([0-9a-z-]#)*=01;34=0=01'
zstyle ':completion:*:*:*:*:processes' command "ps -u $USERNAME -o pid,user,comm -w -w"
zstyle ':completion:*:cd:*' tag-order local-directories directory-stack path-directories
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "$HOME/.zsh/cache"

bindkey -e

autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search

bindkey '^[[H' beginning-of-line
bindkey '^[[F' end-of-line
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^r' history-incremental-search-backward
bindkey ' ' magic-space
bindkey '^[[Z' reverse-menu-complete
bindkey '^?' backward-delete-char
bindkey '^[[3~' delete-char

autoload -U edit-command-line
zle -N edit-command-line
bindkey '\C-x\C-e' edit-command-line

autoload -U colors && colors

export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
alias ls='ls -G'

autoload -Uz url-quote-magic bracketed-paste-magic
zle -N self-insert url-quote-magic
zle -N bracketed-paste bracketed-paste-magic

# gets the current branch from git
function git_current_branch() {
  local ref
  ref=$(GIT_OPTIONAL_LOCKS=0 command git symbolic-ref --quiet HEAD 2>/dev/null)
  local ret=$?
  if [[ $ret != 0 ]]; then
    [[ $ret == 128 ]] && return
    ref=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2>/dev/null) || return
  fi
  echo ${ref#refs/heads/}
}

function parse_git_dirty() {
  local STATUS
  STATUS=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)
  [[ -n $STATUS ]] && echo "*"
}

function git_prompt_info() {
  GIT_OPTIONAL_LOCKS=0 command git rev-parse --git-dir &>/dev/null || return 0
  local ref
  ref=$(GIT_OPTIONAL_LOCKS=0 command git symbolic-ref --short HEAD 2>/dev/null) \
    || ref=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2>/dev/null) \
    || return 0
  echo "%{$fg[green]%}${ref:gs/%/%%}$(parse_git_dirty)%{$reset_color%} "
}

PROMPT='λ %~/ $(git_prompt_info)%{$reset_color%}'

alias cat=bat
alias vim=nvim
alias gaa="git add . && git reset AGENTS.md CLAUDE.md"
alias oc="opencode"
alias gfc="vim $HOME/Library/Application\ Support/com.mitchellh.ghostty/config"

alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias md='mkdir -p'
alias rd=rmdir

# force update neovim whenever I do something stupid
function nvu() {
  nvim --headless "+Lazy! sync" +qa
}

# little wrapper to ask questions to claude (haiku to make it faster)
function ask() {
  local model="claude-haiku-4-5-20251001"
  local -a prompt_parts=()

  while [[ $# -gt 0 ]]; do
    case "$1" in
      *)
        prompt_parts+=("$1")
        shift
        ;;
    esac
  done

  local prompt=""
  if [[ ${#prompt_parts[@]} -gt 0 ]]; then
    prompt="$(printf '%s ' "${prompt_parts[@]}")"
    prompt="${prompt% }"
  elif [[ ! -t 0 ]]; then
    prompt="$(cat)"
  else
    echo "ask: provide a prompt argument or pipe text in" >&2
    return 1
  fi

  claude --model "$model" --print -- "$prompt" | glow -
}

# quickly pulls remote to the current branch
function gll() {
  git pull --rebase origin $(git_current_branch)
}

# quickly commits your tracked changes to the current branch
function gpp() {
  git push origin $(git_current_branch)
}

# compare the files changed between two branches
function gds() {
  git diff --name-only -z | grep -z "$1" | xargs -0 git diff --
}

# shortcut handler to merge a branch to main and delete its remote counterpart
gmm() {
  local branch=$(git branch --show-current)

  if [[ "$branch" == "main" ]]; then
    echo "Already on main, nothing to merge."
    return 1
  fi

  command git checkout main && \
    command git pull origin main && \
    command git merge "$branch" && \
    command git push origin main && \
    command git branch -d "$branch" && \
    command git push origin --delete "$branch"

  echo "Merged, pushed, and deleted '$branch'."
}

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

eval "$(fnm env --use-on-cd)"

source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
