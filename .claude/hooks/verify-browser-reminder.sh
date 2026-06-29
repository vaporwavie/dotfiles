#!/usr/bin/env bash
# Stop hook: if UI files were edited this session but agent-browser was never
# used, remind once to verify. Conservative — any doubt yields exit 0 (allow stop).
set -uo pipefail

input="$(cat)"

# Never loop: if we already blocked once this stop, let it through.
active="$(printf '%s' "$input" | jq -r '.stop_hook_active // false' 2>/dev/null || echo false)"
[[ "$active" == "true" ]] && exit 0

transcript="$(printf '%s' "$input" | jq -r '.transcript_path // empty' 2>/dev/null || true)"
[[ -n "$transcript" && -f "$transcript" ]] || exit 0

ui_edited="$(jq -r '
  .. | objects
  | select(.type? == "tool_use")
  | select(.name? == "Edit" or .name? == "Write" or .name? == "MultiEdit" or .name? == "NotebookEdit")
  | (.input.file_path // .input.notebook_path // empty)
' "$transcript" 2>/dev/null | grep -iE '\.(tsx|jsx|vue|svelte|css|scss|less|html)$' | head -1 || true)"
[[ -n "$ui_edited" ]] || exit 0

used_browser="$(jq -r '
  .. | objects
  | select(.type? == "tool_use")
  | select(.name? == "Bash")
  | (.input.command // empty)
' "$transcript" 2>/dev/null | grep -c 'agent-browser' || echo 0)"
[[ "${used_browser:-0}" -gt 0 ]] && exit 0

echo "UI files were edited but agent-browser was never used to verify them. Per the Verification rules, confirm the UI/UX in agent-browser (then 'agent-browser close --all') before stopping." >&2
exit 2
