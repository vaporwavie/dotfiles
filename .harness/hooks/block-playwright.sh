#!/usr/bin/env bash
# PreToolUse hook (Bash + mcp__node_repl__js): block Playwright/Puppeteer.
# agent-browser is the only sanctioned browser driver. Default: allow (exit 0);
# block with exit 2 so the reason is fed back to the model.
set -uo pipefail

input="$(cat)"

cmd="$(printf '%s' "$input" | jq -r '(.tool_input.command // .tool_input.code // .tool_input.js // "")' 2>/dev/null || true)"
[[ -n "$cmd" ]] || exit 0

# Match real Playwright/Puppeteer usage, not incidental mentions (configs, greps).
pat='puppeteer|playwright-core|playwright/test|npx[[:space:]]+playwright|(yarn|pnpm|bun)[[:space:]]+playwright|playwright[[:space:]]+(test|install|codegen|open|show-report)|(from|require|import)[[:space:](]*[^a-zA-Z0-9_]playwright|(chromium|firefox|webkit|browserType)\.launch'

if printf '%s' "$cmd" | grep -qiE "$pat"; then
  echo "Playwright/Puppeteer is disabled here — agent-browser is the only browser tool. Use it for all browser work (open/click/type/read, screenshots, verification). Start with: agent-browser skills get core --full" >&2
  exit 2
fi
exit 0
