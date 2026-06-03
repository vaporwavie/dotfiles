# AGENTS

## Purpose

Keep this file small. It should capture durable local preferences, machine-specific commands, and workflows that are unlikely to change when the model changes.

Do not add generic model-behavior steering, reasoning-process prompts, model-specific prompt workarounds, or one-off task notes.

## Working Style

- Be direct and concise in chat.
- Push back when an approach is materially wrong, and propose a simpler alternative.
- Avoid over-engineering: reuse existing functions, avoid thin wrappers, and prefer straightforward control flow.

## Coding

- My main stack is TypeScript, JavaScript, Node, and Swift. Otherwise, match the repo.
- Verify before claiming absence or breakage: follow imports and adjacent code enough to support the claim.
- Default to no comments. Add comments only for subtle invariants or non-obvious constraints.
- New functionality should include tests. Bug fixes should include regression tests when practical. If a change is too small for tests, say so.
- Install obvious, well-known dependencies when the need is clear. Ask before adding anything heavyweight, niche, security-sensitive, or likely to bloat the lockfile.
- Use English for code, comments, docs, examples, commits, configs, error messages, and tests.

## Tooling

- Files: `fd`
- Text: `rg`
- Code structure: `ast-grep`
- Selection: `fzf`
- JSON: `jq`
- YAML/XML: `yq`
- Shell affordance tests: `$HOME/.codex/bin/just-bash`
- Node tooling in non-interactive zsh comes from `~/.local/bin/fnm-node-shim`, symlinked as `node`, `npm`, `npx`, `corepack`, `pnpm`, `pnpx`, `yarn`, and `yarnpkg`. If `pnpm` is missing, verify `~/.local/bin` precedes Homebrew in `.zprofile` and check `corepack install -g pnpm@10.31.0`.

## Artifacts

- For substantial plans, design explorations, reports, reviews, or interactive throwaway tools, write one self-contained HTML file by default.
- Use Markdown for short terminal answers, commit messages, AGENTS.md/CLAUDE.md, README/contributor docs, and files meant to be hand-edited.
- For generated HTML, SVG, screenshots, mockups, or static previews, write a real file and serve it from `localhost` or `127.0.0.1`. Do not use `data:` URLs in the Codex in-app browser.

## Git And PRs

- Commit only when asked. Use `<type>(<scope>): <subject>`, with type `feat|fix|docs|style|refactor|test|chore|perf`, subject <= 50 chars, imperative mood, and no trailing period.
- For PR messages, check `.github/pull_request_template.md`. If it exists, write `pr.md` using that template; if not, ask how to structure it. Keep PR copy product-facing by default: behavior, workflow impact, business reason, verification, and reviewer-relevant risk.
