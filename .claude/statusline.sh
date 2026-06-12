#!/bin/sh
# Claude Code status line
# Reads JSON from stdin, prints a styled one-liner.
# Based on zsh PROMPT: λ %~/ $(git_prompt_info)%{$reset_color%}

input=$(cat)

# --- Extract fields ---
model=$(printf '%s' "$input" | jq -r '.model.display_name // "unknown model"')
effort=$(printf '%s' "$input" | jq -r '.effort.level // empty')
cwd=$(printf '%s' "$input" | jq -r '.workspace.current_dir // .cwd // ""')
used_pct=$(printf '%s' "$input" | jq -r '.context_window.used_percentage // empty')
total_in=$(printf '%s' "$input" | jq -r '.context_window.total_input_tokens // 0')
total_out=$(printf '%s' "$input" | jq -r '.context_window.total_output_tokens // 0')

# --- Derived values ---
total_tokens=$((total_in + total_out))

# Git branch and dirty status (skip locks, suppress errors)
git_branch=""
git_dirty=""
if [ -n "$cwd" ] && git -C "$cwd" --no-optional-locks rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  git_branch=$(git -C "$cwd" --no-optional-locks symbolic-ref --short HEAD 2>/dev/null)
  [ -z "$git_branch" ] && git_branch=$(git -C "$cwd" --no-optional-locks rev-parse --short HEAD 2>/dev/null)

  # Check for dirty working tree
  if [ -n "$git_branch" ]; then
    STATUS=$(git -C "$cwd" --no-optional-locks status --porcelain --ignore-submodules=dirty 2>/dev/null | head -n 1)
    [ -n "$STATUS" ] && git_dirty="*"
  fi
fi

# --- ANSI helpers ---
RESET='\033[0m'
BOLD='\033[1m'
DIM='\033[2m'

# Foreground colors
FG_WHITE='\033[97m'
FG_CYAN='\033[96m'
FG_YELLOW='\033[93m'
FG_MAGENTA='\033[95m'
FG_BLUE='\033[94m'
FG_GREEN='\033[92m'
FG_RED='\033[91m'
FG_GRAY='\033[90m'

SEP="${DIM}${FG_GRAY} | ${RESET}"

# --- Context bar ---
bar=""
bar_color="$FG_GREEN"
if [ -n "$used_pct" ]; then
  used_int=$(printf '%.0f' "$used_pct")

  if [ "$used_int" -ge 80 ]; then
    bar_color="$FG_RED"
  elif [ "$used_int" -ge 50 ]; then
    bar_color="$FG_YELLOW"
  fi

  filled=$(( used_int / 10 ))
  empty=$(( 10 - filled ))
  i=0
  while [ $i -lt $filled ]; do
    bar="${bar}█"
    i=$(( i + 1 ))
  done
  i=0
  while [ $i -lt $empty ]; do
    bar="${bar}░"
    i=$(( i + 1 ))
  done

  ctx_section="${bar_color}${bar}${RESET} ${DIM}$(printf '%.1f' "$used_pct")%%${RESET}"
else
  ctx_section="${DIM}no ctx${RESET}"
fi

# --- Token counts ---
fmt_num() {
  n=$1
  if [ "$n" -ge 1000000 ]; then
    printf '%.1fM' "$(echo "$n" | awk '{printf "%.1f", $1/1000000}')"
  elif [ "$n" -ge 1000 ]; then
    printf '%.1fk' "$(echo "$n" | awk '{printf "%.1f", $1/1000}')"
  else
    printf '%d' "$n"
  fi
}

tok_total=$(fmt_num "$total_tokens")
tok_in=$(fmt_num "$total_in")
tok_out=$(fmt_num "$total_out")
tok_section="${DIM}$(printf '%s' "$tok_total") (↑${tok_in} ↓${tok_out})${RESET}"

# --- Lambda prompt section (matching zsh PROMPT) ---
lambda_section="${FG_CYAN}λ${RESET}"

# --- Directory (full path, matching %~/) ---
dir_section="${FG_BLUE}${cwd}/${RESET}"

# --- Git section (matching git_prompt_info with green + dirty indicator) ---
if [ -n "$git_branch" ]; then
  git_section="${FG_GREEN}${git_branch}${git_dirty}${RESET}"
else
  git_section=""
fi

# --- Model (with effort) ---
if [ -n "$effort" ]; then
  model_section="${BOLD}${FG_CYAN}${model}${RESET} ${DIM}(${effort})${RESET}"
else
  model_section="${BOLD}${FG_CYAN}${model}${RESET}"
fi

# --- Output ---
# Format: λ /path/to/dir/ branch* | model | ctx | tokens
if [ -n "$git_section" ]; then
  printf "${lambda_section} ${dir_section}${git_section}${SEP}${model_section}${SEP}${ctx_section}${SEP}${tok_section}\n"
else
  printf "${lambda_section} ${dir_section}${SEP}${model_section}${SEP}${ctx_section}${SEP}${tok_section}\n"
fi
