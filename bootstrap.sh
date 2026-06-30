#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_root="${TARGET_ROOT:-$HOME}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${BACKUP_ROOT:-$target_root/.dotfiles-backup/$timestamp}"
dry_run=0
install_tools=1

# Agent CLIs installed from their upstream npm packages rather than vendored in
# this repo. Keep these as bare npm package names.
npm_global_tools=(
  agent-browser
  just-bash
)

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--dry-run] [--no-tools]

Symlink tracked dotfiles from this repo into TARGET_ROOT (default: $HOME).
Each target becomes a symlink back into the repo, so edits on either side stay
in sync. Existing real files are backed up to BACKUP_ROOT before being replaced.

Also installs the agent CLIs (agent-browser, just-bash) from their upstream npm
packages, so the repo never vendors a copy of them.

Options:
  -n, --dry-run   Preview changes without writing anything
      --no-tools  Skip installing the agent CLIs from npm

Examples:
  ./bootstrap.sh
  ./bootstrap.sh --dry-run
  ./bootstrap.sh --no-tools
  TARGET_ROOT=/tmp/test-home ./bootstrap.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      dry_run=1
      ;;
    --no-tools)
      install_tools=0
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown argument: $1" >&2
      usage >&2
      exit 1
      ;;
  esac
  shift
done

list_paths() {
  if git -C "$repo_root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    git -C "$repo_root" ls-files | awk -F/ '
      ($1 ~ /^\./ &&
       $1 != ".git" &&
       $1 != ".github" &&
       $1 != ".DS_Store" &&
       $1 != ".dotfiles-backup") ||
      index($0, "Library/Application Support/") == 1 {
        print $0
      }
    ' | sort -u
  else
    find "$repo_root" \
      \( -path "$repo_root/.git" -o -path "$repo_root/.git/*" \
      -o -path "$repo_root/.github" -o -path "$repo_root/.github/*" \
      -o -path "$repo_root/.dotfiles-backup" -o -path "$repo_root/.dotfiles-backup/*" \) -prune -o \
      \( -type f -o -type l \) -print |
      while IFS= read -r path; do
        rel="${path#$repo_root/}"
        first="${rel%%/*}"
        if { [[ "$first" == .* && "$first" != ".DS_Store" ]] || [[ "$rel" == "Library/Application Support/"* ]]; }; then
          printf '%s\n' "$rel"
        fi
      done | sort -u
  fi
}

paths_differ() {
  local src="$1"
  local dest="$2"

  # Up to date only when dest is already a symlink pointing at src.
  if [[ -L "$dest" && "$(readlink "$dest")" == "$src" ]]; then
    return 1
  fi
  return 0
}

backup_path() {
  local src="$1"
  local rel="$2"
  local backup="$backup_root/$rel"

  mkdir -p "$(dirname -- "$backup")"
  cp -PR "$src" "$backup"
}

install_path() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname -- "$dest")"
  rm -rf "$dest"
  ln -s "$src" "$dest"
}

ensure_npm_tools() {
  [[ "$install_tools" -eq 1 ]] || return 0
  [[ ${#npm_global_tools[@]} -gt 0 ]] || return 0

  echo "Ensuring agent CLIs from npm"

  if ! command -v npm >/dev/null 2>&1; then
    echo "warn    npm not found; skipping $(IFS=', '; echo "${npm_global_tools[*]}")" >&2
    return 0
  fi

  local pkg
  for pkg in "${npm_global_tools[@]}"; do
    if command -v "$pkg" >/dev/null 2>&1; then
      echo "skip    $pkg (already installed)"
      continue
    fi
    echo "install $pkg (npm install -g)"
    if [[ "$dry_run" -eq 0 ]]; then
      npm install -g "$pkg"
    fi
  done
}

paths="$(list_paths)"

if [[ -z "$paths" ]]; then
  echo "No dotfiles found to install."
  exit 0
fi

backed_up=0
installed=0
skipped=0

echo "Linking dotfiles into $target_root"

while IFS= read -r rel_path; do
  [[ -n "$rel_path" ]] || continue

  src="$repo_root/$rel_path"
  dest="$target_root/$rel_path"

  if [[ "$src" == "$dest" ]]; then
    echo "Refusing to install $rel_path onto itself." >&2
    exit 1
  fi

  if ! paths_differ "$src" "$dest"; then
    echo "skip    $rel_path (already linked)"
    skipped=$((skipped + 1))
    continue
  fi

  if [[ -e "$dest" || -L "$dest" ]]; then
    echo "backup  $rel_path -> $backup_root/$rel_path"
    if [[ "$dry_run" -eq 0 ]]; then
      backup_path "$dest" "$rel_path"
    fi
    backed_up=$((backed_up + 1))
  fi

  echo "link    $rel_path -> $dest"
  if [[ "$dry_run" -eq 0 ]]; then
    install_path "$src" "$dest"
  fi
  installed=$((installed + 1))
done <<EOF
$paths
EOF

ensure_npm_tools

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run complete: $installed link(s), $backed_up backup(s), $skipped skipped."
  exit 0
fi

if [[ "$backed_up" -gt 0 ]]; then
  echo "Backups saved in $backup_root"
fi

echo "Done: $installed link(s), $backed_up backup(s), $skipped skipped."
