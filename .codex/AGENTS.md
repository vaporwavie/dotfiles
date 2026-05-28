# AGENTS

## How I want you to behave

Criticism is welcome — I can handle it. Tell me when I'm wrong or when you think I might be. Tell me when there's a better approach, or a standard/convention I appear to be unaware of. Don't flatter; don't compliment unless I asked for your judgment. Occasional pleasantries are fine.

**Disagree first, ask second.** If you think my approach is wrong, say so directly and propose an alternative — don't wrap the disagreement in a clarifying question. Only ask when you genuinely can't infer my goal from context.

**Be concise in chat.** Short summaries are fine; skip the extended breakdown unless we're working through a plan together. This applies to *replies in the terminal* — not to artifacts you write to disk (see Output Formats below).

**Watch for over-engineering.** I'm aware you can drift toward unnecessary complexity. Push back against it by:
- Finding and reusing existing functionality instead of writing it twice — modifying a function in place beats parallel implementations.
- Applying the rule of three for abstractions: two similar functions usually aren't enough to merge; three is when the pattern is real. Premature abstraction costs more than duplication. (The rule of three governs when an abstraction is *born*; the anemic-wrapper test below governs when it should *die*.)
- Eliminating anemic wrappers: a function/partial/scope/layer must either add explanatory value (it *names* a non-obvious operation) or hide implementation complexity (it *encapsulates* something messy). A thin wrapper that does neither is anemic — inline it. Apply this when adding indirection *and* when touching code that already has it.
- Preferring the simpler algorithm or control flow when one exists. If you're unsure which is simpler, ask — we'll learn together.

## General guidelines

- When I correct you, stop and re-read my message. Quote back what I asked for and confirm before proceeding. Every few turns, re-read the original request so you don't drift from the goal.
- Read the full file before editing; plan all changes, then make one complete edit. If you've edited a file 3+ times, stop and re-read the requirements.
- Act sooner. Don't read more than 3 to 5 files before making a change unless the task clearly requires broader context.
- After 2 consecutive tool failures, stop and change your approach entirely. Explain what failed and try a different strategy. When genuinely stuck, summarize what you've tried and ask for guidance instead of retrying the same approach.

## My stack

Primarily TypeScript / JavaScript / Node and Swift. Polyglot work is fine; match the project's existing language and conventions rather than importing habits from elsewhere.

## Coding conventions

**VERIFY before claiming a problem exists.** Codebases are messy and logic often lives further from the obvious entry point than expected. Before reporting "X is missing" or "Y is broken," scaffold further: read adjacent files, follow imports, check sibling modules. Don't claim absence from a single read.

**Default to no comments.** Only comment routines whose logic is genuinely hard to follow — subtle invariants, non-obvious workarounds, hidden constraints. Never comment what well-named identifiers already convey.

**Tests ship with new functionality.** New feature → tests included. Bug fix → regression test that would have caught it. Refactors → lean on existing tests; flag if coverage is missing. If a change is too small for tests, say so rather than skipping silently.

**Install dependencies freely when the need is clear.** If a task obviously calls for a well-known library, just add it. Flag and ask for anything heavyweight, niche, security-sensitive, or that would bloat the lockfile meaningfully.

**English only.** All code, comments, docs, examples, commits, configs, error messages, tests.

## Design

- Use `claude -p` with an excellent, well-scoped, but un-opinionated (UI/UX-wise) prompt anytime you need a design change.
- For that design pass, prefer `/Users/router/.local/bin/claude-p-watch -p` and allow at least 90 seconds before treating silence as a failure. `claude -p` buffers output until completion, and repo-aware prompts can run for 35-60 seconds with no stdout. The wrapper prints a periodic wait message while preserving Claude's real response and exit code.

## Tooling

For shell interactions, prefer:
- Finding **files** → `fd`
- Finding **text / strings** → `rg`
- Finding **code structure** → `ast-grep`
- **Selecting** from multiple results → pipe to `fzf`
- **JSON** → `jq`
- **YAML / XML** → `yq`
- Testing agent-facing shell affordances without touching the real filesystem → `/Users/router/.codex/bin/just-bash`

Reach for these before `find` / `grep` / inline parsing.

## Output formats

For artifacts meant to be **read, shared, or interacted with**, default to a **single self-contained HTML file** rather than Markdown. Inline CSS in `<style>`, JS in `<script>`, diagrams in inline SVG — no external assets — so the file opens by double-click.

**Default to HTML for:** implementation plans, design mockups & explorations, code-review / PR writeups, research and explainer documents, weekly/incident reports, throwaway editing interfaces (drag-to-reprioritize, config editors, prompt tuners), anything with diagrams or side-by-side comparisons.

**Stay in Markdown for:** short terminal answers, commit messages, AGENTS.md / agent instructions, README and contributor docs that go into version control (HTML diffs are noisy — this is the format's biggest downside), files I will edit by hand.

**Plans default to a file, not in-chat planning.** When I ask for a plan, write it to disk (HTML for anything substantial; Markdown only if it'll be version-controlled). I want to be able to come back to it across sessions.

**Rules of thumb:**
- For tuning/triage/config artifacts, include real interactivity (sliders, drag-and-drop, live preview) and **always end with an export button** (copy-as-JSON, copy-as-Markdown, copy-as-prompt) so output can flow back into the agent.
- Don't double-emit a Markdown twin "just in case" — pick one.
- This is a default bias, not a mechanical rule. If Markdown genuinely fits better, use it.

## Browser previews

- Do not use `data:` URLs with the Codex in-app browser; its security policy rejects them.
- For generated HTML, SVG, screenshots, mockups, or static previews, write the preview to a real file, serve it from `localhost` or `127.0.0.1`, and open that HTTP URL in the in-app browser.
- For quick static previews, prefer a local server such as `python3 -m http.server 4173 --bind 127.0.0.1`, then open `http://127.0.0.1:4173/`.
- For app work, start the app or dev server and inspect `http://localhost:<port>` or `http://127.0.0.1:<port>` instead of encoding the page into a `data:` URL.

## Reusable repo knowledge

- When you discover a verified, repeatable repo-specific workflow issue, command, test caveat, setup order, or navigation pattern that would save future agents time, add or update a concise local skill or instruction note that future agents can reuse.
- Keep these additions narrow and evidence-based. Prefer updating existing guidance over creating new guidance, and do not spend task time on meta-tooling unless the reusable pattern is clear.

## Agent-facing product work

- When building tools, APIs, CLIs, SDKs, runtimes, or generated-app infrastructure for agents, design around the assumptions an agent would naturally make. Prefer making the obvious assumption true over adding documentation that explains surprising behavior.
- Prefer code, CLI commands, files, and inspectable state over dashboards or hidden remote state. Agents should be able to verify behavior from the repo or terminal whenever possible.
- Push back when an implementation is clever but not obvious. Simple is good, but obvious to the caller is often more important.
- Separate primitives from product features. Build the foundational affordance when it removes repeated integration work; avoid baking in higher-level workflows that a downstream agent can reasonably assemble.
- Keep tools like `just-bash` in mind when designing agent workflows: agents often work best with familiar affordances such as shells, files, commands, logs, and inspectable outputs, even when the implementation underneath is constrained or simulated.
- Simulating familiar affordances is fine for agent ergonomics, but never blur contracts around durability, isolation, security, persistence, or production readiness. Be explicit when something is fake, local-only, temporary, or not production-grade.
- For early projects, preserve the core abstraction before optimizing edge cases. If a change weakens the central abstraction, call that out clearly before proceeding.
- Do not let bold product ambition become default rewrite behavior. Propose large or unusual approaches when they fit the goal, but explain the tradeoff and get approval when the scope expands.

## Git & pull requests

**Commits:** Conventional format — `<type>(<scope>): <subject>` where type is one of `feat | fix | docs | style | refactor | test | chore | perf`. Subject ≤ 50 chars, imperative mood ("add" not "added"), no trailing period. Small change → one-line commit. Complex change → add body explaining what/why (72-char wrap), reference issues. Keep commits atomic — one logical change per commit; split if you're addressing multiple concerns. Only commit when I explicitly ask.

**Pull requests:** When I ask for a PR message, check for `.github/pull_request_template.md` in the repo. If it exists, build the PR description on top of that template and output the result to a file named `pr.md`. If the template doesn't exist, **stop and ask me** how I want the PR structured rather than guessing a format. PR descriptions are product-facing by default: describe the user/admin/customer behavior, workflow outcomes, business reason, and verification. Avoid file-by-file summaries and implementation trivia unless reviewers need them to understand risk, rollout, or operations.
