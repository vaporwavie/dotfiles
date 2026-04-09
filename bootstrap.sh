#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
target_root="${TARGET_ROOT:-$HOME}"
timestamp="$(date +%Y%m%d-%H%M%S)"
backup_root="${BACKUP_ROOT:-$target_root/.dotfiles-backup/$timestamp}"
dry_run=0

usage() {
  cat <<'EOF'
Usage: ./bootstrap.sh [--dry-run]

Copy tracked dotfiles from this repo into TARGET_ROOT (default: $HOME).
Existing targets are backed up to BACKUP_ROOT before being replaced.

Examples:
  ./bootstrap.sh
  ./bootstrap.sh --dry-run
  TARGET_ROOT=/tmp/test-home ./bootstrap.sh
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -n|--dry-run)
      dry_run=1
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
      $1 ~ /^\./ &&
      $1 != ".git" &&
      $1 != ".github" &&
      $1 != ".DS_Store" &&
      $1 != ".dotfiles-backup" {
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
        if [[ "$first" == .* && "$first" != ".DS_Store" ]]; then
          printf '%s\n' "$rel"
        fi
      done | sort -u
  fi
}

paths_differ() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    return 0
  fi

  if [[ -d "$src" && -d "$dest" ]]; then
    ! diff -qr "$src" "$dest" >/dev/null 2>&1
    return
  fi

  if [[ -f "$src" && -f "$dest" ]]; then
    ! cmp -s "$src" "$dest"
    return
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
  cp -PR "$src" "$dest"
}

paths="$(list_paths)"

if [[ -z "$paths" ]]; then
  echo "No dotfiles found to install."
  exit 0
fi

backed_up=0
installed=0
skipped=0

echo "Installing dotfiles into $target_root"

while IFS= read -r rel_path; do
  [[ -n "$rel_path" ]] || continue

  src="$repo_root/$rel_path"
  dest="$target_root/$rel_path"

  if [[ "$src" == "$dest" ]]; then
    echo "Refusing to install $rel_path onto itself." >&2
    exit 1
  fi

  if ! paths_differ "$src" "$dest"; then
    echo "skip    $rel_path (already up to date)"
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

  echo "install $rel_path -> $dest"
  if [[ "$dry_run" -eq 0 ]]; then
    install_path "$src" "$dest"
  fi
  installed=$((installed + 1))
done <<EOF
$paths
EOF

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run complete: $installed install(s), $backed_up backup(s), $skipped skipped."
  exit 0
fi

if [[ "$backed_up" -gt 0 ]]; then
  echo "Backups saved in $backup_root"
fi

echo "Done: $installed install(s), $backed_up backup(s), $skipped skipped."
