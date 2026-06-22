typeset -U path fpath

export BUN_INSTALL="$HOME/.bun"

path=(
  $HOME/.local/bin
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
  # Full audit once a week; otherwise use the cached dump (-C skips compaudit entirely).
  # Glob qualifier must be evaluated in a globbing context — [[ ]] doesn't expand it.
  local zdump=$HOME/.zcompdump
  local -a _fresh
  _fresh=( $zdump(Nmh-168) )
  if (( ${#_fresh} )); then
    compinit -C -d $zdump
  else
    compinit -i -d $zdump
  fi
  # Bytecode-compile the dump so subsequent shells parse less.
  if [[ -s $zdump && (! -s $zdump.zwc || $zdump -nt $zdump.zwc) ]]; then
    zcompile $zdump
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

export LSCOLORS="Gxfxcxdxbxegedabagacad"
export LS_COLORS="di=1;36:ln=35:so=32:pi=33:ex=31:bd=34;46:cd=34;43:su=30;41:sg=30;46:tw=30;42:ow=30;43"
alias ls='ls -G'

autoload -Uz bracketed-paste-magic
zle -N bracketed-paste bracketed-paste-magic

# vim-with-a-hat: Ghostty's cmd+shift+e / cmd+shift+b paste a temp screen/scrollback
# dump path plus a newline as plain keystrokes, which submits the line. Intercept
# accept-line: if the line is exactly such a dump path, open it in `vh` (its own
# window) instead of executing it. Every other command runs normally.
_vh_accept_line() {
  emulate -L zsh
  setopt extendedglob
  local p=${BUFFER//[$'\r\n']/}
  p=${p##[[:space:]]#}; p=${p%%[[:space:]]#}
  if [[ -f $p && ${p:t} == (screen|scrollback).txt ]] \
     && [[ $p == ${TMPDIR}* || $p == /private/var/folders/* || $p == /tmp/* ]]; then
    vh "$p" >/dev/null 2>&1 &!
    BUFFER=
  fi
  zle .accept-line
}
zle -N accept-line _vh_accept_line

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

# --- Async git prompt (zsh-async) ----------------------------------------
# The branch name is cheap and resolved synchronously; the dirty marker
# (`*`) is computed in a background worker and the prompt is redrawn when
# it arrives. Net result: prompt never blocks on `git status`.

source $HOME/.zsh/async.zsh
async_init

typeset -g _git_branch=""
typeset -g _git_dirty=""
typeset -g _git_last_dir=""

_git_branch_sync() {
  local ref
  ref=$(GIT_OPTIONAL_LOCKS=0 command git symbolic-ref --short HEAD 2>/dev/null) \
    || ref=$(GIT_OPTIONAL_LOCKS=0 command git rev-parse --short HEAD 2>/dev/null) \
    || return 1
  print -r -- "${ref:gs/%/%%}"
}

_git_dirty_async() {
  cd -q "$1"
  local s
  s=$(GIT_OPTIONAL_LOCKS=0 command git status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)
  [[ -n $s ]] && print -n '*'
}

_git_async_callback() {
  local job=$1 code=$2 output=$3
  [[ $job == '[async]' ]] && return
  if [[ $job == _git_dirty_async ]]; then
    _git_dirty=$output
    zle && zle reset-prompt
  fi
}

async_start_worker git_prompt_worker -n
async_register_callback git_prompt_worker _git_async_callback

_git_prompt_precmd() {
  if ! command git rev-parse --git-dir &>/dev/null; then
    _git_branch=""; _git_dirty=""; _git_last_dir=""
    return
  fi
  _git_branch=$(_git_branch_sync)
  # Reset dirty marker on directory change so we don't show a stale `*`.
  if [[ $PWD != $_git_last_dir ]]; then
    _git_dirty=""
    _git_last_dir=$PWD
  fi
  async_flush_jobs git_prompt_worker
  async_job git_prompt_worker _git_dirty_async "$PWD"
}

git_prompt_info() {
  [[ -n $_git_branch ]] || return 0
  print -n "%F{green}${_git_branch}${_git_dirty}%f "
}

autoload -Uz add-zsh-hook
add-zsh-hook precmd _git_prompt_precmd

PROMPT='λ %~/ $(git_prompt_info)%f'

alias cat=bat
alias vim=nvim
alias c="open -a Cursor"
alias cc="CLAUDE_CODE_NO_FLICKER=1 claude --dangerously-skip-permissions"

# git
alias ga="git add"
alias gaa="git add ."
alias gd="git diff"
alias gl="git pull"
alias gst="git status"
alias gc="git commit -S"
alias gco="git checkout"

alias gfc="vim $HOME/Library/Application\ Support/com.mitchellh.ghostty/config"

# codex — config.toml default is "high"; aliases are per-invocation overrides
alias cx="$HOME/.local/bin/cx"
alias cxx="codex -c model_reasoning_effort=xhigh"

# kvm
alias engine="bash ~/Workspace/kvm/engine.sh"
alias pnmac="bash ~/Workspace/kvm/pnmac.sh"

function agent_welcome() {
  [[ -o interactive ]] || return 0

  print -P "%F{244}codex:%f %F{245}cx%f, %F{245}cx -w%f, %F{245}cx -C <dir>%f"
  print -P "%F{244}claude:%f %F{245}cc%f%f"
}

agent_welcome

# dirs
alias -g ...='../..'
alias -g ....='../../..'
alias -g .....='../../../..'
alias md='mkdir -p'
alias rd=rmdir

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
    command git merge -S "$branch" && \
    command git push origin main && \
    command git branch -d "$branch" && \
    command git push origin --delete "$branch"

  echo "Merged, pushed, and deleted '$branch'."
}

# fzf — fuzzy completion (^T = files, ^R = history, alt-c = cd).
# Source key-bindings only if fzf is on the path; cheap (no subprocess).
if [[ -d /opt/homebrew/opt/fzf/shell ]]; then
  source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
  source /opt/homebrew/opt/fzf/shell/completion.zsh
  # Use rg for file-listing — respects .gitignore, faster than `find`.
  if (( $+commands[rg] )); then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border --info=inline'
fi

# bat — pager + man-page colorizer; matches the active ghostty theme.
if (( $+commands[bat] )); then
  export BAT_THEME="ansi"
  export MANPAGER="sh -c 'col -bx | bat -l man -p'"
  export MANROFFOPT="-c"
fi

[[ -s "$HOME/.bun/_bun" ]] && source "$HOME/.bun/_bun"

# Lazy-load fnm: avoids the ~10–20ms `fnm env` eval and the chpwd hook
# until you actually run node/npm/npx/pnpm/yarn/corepack or a known global
# Node CLI in this shell.
# Wrappers redefine the loader inline so they survive Claude Code's shell
# snapshot, which drops underscore-prefixed functions.
for _cmd in node npm npx pnpm yarn corepack vercel vc; do
  eval "${_cmd}() {
    unfunction node npm npx pnpm yarn corepack vercel vc 2>/dev/null
    eval \"\$(fnm env --use-on-cd)\"
    ${_cmd} \"\$@\"
  }"
done
unset _cmd

# >>> grok installer >>>
export PATH="$HOME/.grok/bin:$PATH"
fpath=(~/.grok/completions/zsh $fpath)
autoload -Uz compinit && compinit -C
# <<< grok installer <<<


function grok() {
  env \
    VIBEPROXY_API_KEY="${VIBEPROXY_API_KEY:?Set VIBEPROXY_API_KEY}" \
    XAI_API_KEY="${XAI_API_KEY:?Set XAI_API_KEY}" \
    GROK_MODELS_BASE_URL="${GROK_MODELS_BASE_URL:-http://localhost:8317/v1}" \
    RUST_LOG=error \
    /Users/router/.grok/bin/grok "$@"
}

# bun completions
[ -s "/private/var/folders/mz/830vr53s6233ywqkw8wkkbcr0000gn/T/tmp.1by5RiOPPT/_bun" ] && source "/private/var/folders/mz/830vr53s6233ywqkw8wkkbcr0000gn/T/tmp.1by5RiOPPT/_bun"

# Pi
export PATH="/Users/router/.local/share/fnm/node-versions/v22.19.0/installation/bin:$PATH"
