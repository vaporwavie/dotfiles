#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
source_root="${SOURCE_ROOT:-$HOME}"
dry_run=0

usage() {
  cat <<'EOF'
Usage: ./updater.sh [--dry-run]

Copy tracked dotfiles from SOURCE_ROOT (default: $HOME) back into this repo.

Examples:
  ./updater.sh
  ./updater.sh --dry-run
  SOURCE_ROOT=/tmp/test-home ./updater.sh
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
  git -C "$repo_root" ls-files | awk -F/ '
    $1 ~ /^\./ &&
    $1 != ".git" &&
    $1 != ".github" &&
    $1 != ".DS_Store" &&
    $1 != ".dotfiles-backup" {
      print $0
    }
  ' | sort -u
}

paths_differ() {
  local src="$1"
  local dest="$2"

  if [[ ! -e "$dest" && ! -L "$dest" ]]; then
    return 0
  fi

  if [[ -f "$src" && -f "$dest" ]]; then
    ! cmp -s "$src" "$dest"
    return
  fi

  return 0
}

secret_lines() {
  local src="$1"

  if ! grep -Iq . "$src"; then
    return 1
  fi

  grep -nEi '(^|[^A-Za-z0-9_])([A-Za-z0-9_-]*(api[_-]?key|auth[_-]?token|access[_-]?token|refresh[_-]?token|secret|password|private[_-]?key|access[_-]?key)[A-Za-z0-9_-]*)[[:space:]]*[=:]' "$src" |
    grep -Eiv '(\$\{|\$[A-Za-z_][A-Za-z0-9_]*|<redacted>|placeholder|changeme|example|your_|""|'\'''\''|null)' |
    cut -d: -f1
}

sync_path() {
  local src="$1"
  local dest="$2"

  mkdir -p "$(dirname -- "$dest")"
  rm -rf "$dest"
  cp -PR "$src" "$dest"
}

paths="$(list_paths)"

if [[ -z "$paths" ]]; then
  echo "No tracked dotfiles found to update."
  exit 0
fi

updated=0
skipped=0
missing=0
refused=0

echo "Updating repo dotfiles from $source_root"

while IFS= read -r rel_path; do
  [[ -n "$rel_path" ]] || continue

  src="$source_root/$rel_path"
  dest="$repo_root/$rel_path"

  if [[ "$src" == "$dest" ]]; then
    echo "Refusing to update $rel_path from itself." >&2
    exit 1
  fi

  if [[ ! -e "$src" && ! -L "$src" ]]; then
    echo "missing $rel_path (not found in $source_root)"
    missing=$((missing + 1))
    continue
  fi

  unsafe_lines="$(secret_lines "$src" || true)"
  if [[ -n "$unsafe_lines" ]]; then
    echo "refuse  $rel_path (possible secret on line(s): $(printf '%s' "$unsafe_lines" | paste -sd, -))" >&2
    refused=$((refused + 1))
    continue
  fi

  if ! paths_differ "$src" "$dest"; then
    echo "skip    $rel_path (already up to date)"
    skipped=$((skipped + 1))
    continue
  fi

  echo "update  $rel_path <- $src"
  if [[ "$dry_run" -eq 0 ]]; then
    sync_path "$src" "$dest"
  fi
  updated=$((updated + 1))
done <<EOF
$paths
EOF

if [[ "$dry_run" -eq 1 ]]; then
  echo "Dry run complete: $updated update(s), $skipped skipped, $missing missing, $refused refused."
  if [[ "$refused" -gt 0 ]]; then
    exit 2
  fi
  exit 0
fi

echo "Done: $updated update(s), $skipped skipped, $missing missing, $refused refused."
if [[ "$refused" -gt 0 ]]; then
  exit 2
fi
