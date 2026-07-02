# AGENTS

This is the canonical harness ruleset shared by every coding agent (Codex, Claude Code, and others). It lives in `~/.harness/AGENTS.md`; the per-agent entry points (`~/.codex/AGENTS.md`, `~/.claude/CLAUDE.md`) point back here, so edit this file and nowhere else.

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
- Never write decorative or redundant comments: no section-banner/divider comments (e.g. `// --- The overlay ---`), no comments that just restate the code or label an obvious block. They are harmful noise. If a comment doesn't carry information the code can't, omit it.
- Don't overexplain. When a comment is warranted, keep it lean: one short line on the why, not a narration of the code or a multi-line essay.
- New functionality should include tests. Bug fixes should include regression tests when practical. If a change is too small for tests, say so.
- Install obvious, well-known dependencies when the need is clear. Ask before adding anything heavyweight, niche, security-sensitive, or likely to bloat the lockfile.
- Use English for code, comments, docs, examples, commits, configs, error messages, and tests.
- On code comments: Please make the comments concise and timeless. Avoid tombstone-like comment saying thing was removed

## Verification

- agent-browser is the ONLY browser tool. Use it for all browser work — both while developing/iterating and for final verification. Never use Playwright, Puppeteer, or any other browser driver for this (including a browser MCP server or a `node_repl` playwright import).
- It is one continuous loop, not two passes: do not drive dev with another browser tool and then re-verify with agent-browser. That duplicates the whole flow and burns tokens.
- After every change, confirm UI/UX in agent-browser and fix any issues. Do not stop until all changes have been verified.
- When using agent-browser, always close sessions with `agent-browser close --all` when done. If you started any dev server for verification, record its PID and kill it before finalizing; also check for leftover fallback-port dev servers you may have started.

## Tooling

- Files: `fd`
- Text: `rg`
- Code structure: `ast-grep`
- Selection: `fzf`
- JSON: `jq`
- YAML/XML: `yq`
- Shell affordance tests: `just-bash` (https://github.com/vercel-labs/just-bash)
- Node tooling in non-interactive zsh comes from `~/.local/bin/fnm-node-shim`, symlinked as `node`, `npm`, `npx`, `corepack`, `pnpm`, `pnpx`, `yarn`, and `yarnpkg`. If `pnpm` is missing, verify `~/.local/bin` precedes Homebrew in `.zprofile` and check `corepack install -g pnpm@10.31.0`.

## Model Delegation

When orchestrating subagents/workflows or handing off work, pick models by these rankings (higher = better). Cost reflects what I actually pay, not list price. Intelligence is how hard a problem the model can take unsupervised. Taste covers UI/UX, code quality, API design, and copy.

| model | cost | intelligence | taste | reach via |
|---|---|---|---|---|
| gpt-5.5 | 9 | 8 | 5 | `codex exec` (my `~/.codex/config.toml` default) |
| glm-5.2 | 9 | 6 | 4 | `codex exec -p baseten-glm` |
| kimi-k2.7 | 9 | 6 | 5 | `codex exec -p baseten-kimi` |
| sonnet-5 | 5 | 5 | 7 | Agent/Workflow `model` param |
| opus-4.8 | 4 | 7 | 8 | Agent/Workflow `model` param |
| fable-5 | 2 | 9 | 9 | main session, or `model` param |

How to apply:

- These are defaults, not limits. Standing permission to override: if a cheaper model's output doesn't meet the bar, rerun or redo the work with a smarter model without asking. Judge the output, not the price tag; escalating costs less than shipping mediocre work.
- Cost is a tie-breaker only; when axes conflict for anything that ships, intelligence > taste > cost.
- Bulk/mechanical work (clear-spec implementation, migrations, data analysis, codebase sweeps): gpt-5.5.
- Token-hungry work (computer use, whole-codebase analysis, long log digs) must not run in the orchestrator's own context: delegate it and have only the result reported back.
- Anything user-facing (UI, copy, API design) needs taste ≥ 7.
- Reviews of plans/implementations: fable-5 or opus-4.8, optionally gpt-5.5 (`codex exec review`) as an extra independent perspective.
- Don't use Haiku; gpt-5.5, glm-5.2, and kimi-k2.7 are cheaper and smarter.

Mechanics:

- Codex shares no conversation context, so every delegated prompt must be self-contained: working dir (`-C <dir>`), spec, constraints, acceptance criteria, and the exact shape of the report to return.
- Headless calls must redirect stdin (`</dev/null`) — codex otherwise blocks reading piped input forever — and need `-C <git repo>` or `--skip-git-repo-check` when outside a trusted directory.
- Investigation/analysis: `codex exec -s read-only "<prompt>"`. Implementation: `codex exec -s workspace-write "<prompt>"`. Reviews: `codex exec review`. Add `-o <file>` to capture the final message cleanly, `--output-schema <file>` for structured JSON.
- The Agent/Workflow `model` param only takes Claude models. To use gpt-5.5 inside a workflow, spawn a thin wrapper agent (`model: 'sonnet'`, low effort) whose prompt writes the self-contained codex prompt, runs `codex exec` via Bash, and returns the last message verbatim.
- Delegated UI/UX work still obeys Verification: the codex prompt must tell it to use `agent-browser` (never its own browser plugins) and close sessions when done.

## Artifacts

- For substantial plans, design explorations, reports, reviews, or interactive throwaway tools, write one self-contained HTML file by default.
- Use Markdown for short terminal answers, commit messages, AGENTS.md/CLAUDE.md, README/contributor docs, and files meant to be hand-edited.
- For generated HTML, SVG, screenshots, mockups, or static previews, write a real file instead of a `data:` URL or chat-only blob. When previewing in an in-app browser, serve it from `localhost` or `127.0.0.1` rather than a `data:` URL.

## Git And PRs

When writing a PR focus on two possible outcomes. Check `.github/pull_request_template.md`.

If it exists:

-  Write `pr.md` using that template; if not, ask how to structure it. Keep PR copy product-facing by default: behavior, workflow impact, business reason, verification, and reviewer-relevant risk. Create the PR. Delete `pr.md` afterwards.


If it does not:

Use this template:

```
you can grab the branch name that *should* be the task id. If that's the case, write here "Closes [taskId]"

## What
product explained

## Why
what it aims

## How
how it is done
````

Notes:

- Commit only when asked. Use `<type>(<scope>): <subject>`, with type `feat|fix|docs|style|refactor|test|chore|perf`, subject <= 50 chars, imperative mood, and no trailing period.
- Never hard-wrap prose in PR/issue bodies and comments. GitHub renders single newlines there as `<br>`, so column-wrapped paragraphs come out as choppy mid-sentence breaks. Put each paragraph and list item on one line and let it soft-wrap. Hard breaks still belong in tables (one row per line) and code/mermaid fences.
