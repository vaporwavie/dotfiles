# Working with me

**Disagree first, ask second.** If you think my approach is wrong, say so directly and propose an alternative — don't wrap the disagreement in a clarifying question. Only ask when you genuinely can't infer my goal from context.

**Be concise in chat.** Short summaries are fine; skip the extended breakdown unless we're working through a plan together. This applies to *replies in the terminal* — not to artifacts you write to disk (see Output Formats below).

**Watch for over-engineering.** I'm aware you can drift toward unnecessary complexity. Push back against it by:
- Finding and reusing existing functionality instead of writing it twice — modifying a function in place beats parallel implementations.
- Applying the rule of three for abstractions: two similar functions usually aren't enough to merge; three is when the pattern is real. Premature abstraction costs more than duplication. (The rule of three governs when an abstraction is *born*; the anemic-wrapper test below governs when it should *die*.)
- Eliminating anemic wrappers: a function/partial/scope/layer must either add explanatory value (it *names* a non-obvious operation) or hide implementation complexity (it *encapsulates* something messy). A thin wrapper that does neither is anemic — inline it. Apply this when adding indirection *and* when touching code that already has it.
- Preferring the simpler algorithm or control flow when one exists. If you're unsure which is simpler, ask — we'll learn together.

## Coding conventions

**VERIFY before claiming a problem exists.** Codebases are messy and logic often lives further from the obvious entry point than expected. Before reporting "X is missing" or "Y is broken," scaffold further: read adjacent files, follow imports, check sibling modules. Don't claim absence from a single read.

**Default to no comments.** Only comment routines whose logic is genuinely hard to follow — subtle invariants, non-obvious workarounds, hidden constraints. Never comment what well-named identifiers already convey.

**Tests ship with new functionality.** New feature → tests included. Bug fix → regression test that would have caught it. Refactors → lean on existing tests; flag if coverage is missing. If a change is too small for tests, say so rather than skipping silently.

**Install dependencies freely when the need is clear.** If a task obviously calls for a well-known library, just add it. Flag and ask for anything heavyweight, niche, security-sensitive, or that would bloat the lockfile meaningfully.

**English only.** All code, comments, docs, examples, commits, configs, error messages, tests.

## Tooling

For shell interactions, prefer:
- Finding **files** → `fd`
- Finding **text / strings** → `rg`
- Finding **code structure** → `ast-grep`
- **Selecting** from multiple results → pipe to `fzf`
- **JSON** → `jq`
- **YAML / XML** → `yq`

All six are installed on this machine. Reach for them before `find` / `grep` / inline parsing.

## Output formats

For artifacts meant to be **read, shared, or interacted with**, default to a **single self-contained HTML file** rather than Markdown. Inline CSS in `<style>`, JS in `<script>`, diagrams in inline SVG — no external assets — so the file opens by double-click.

**Default to HTML for:** implementation plans, design mockups & explorations, code-review / PR writeups, research and explainer documents, weekly/incident reports, throwaway editing interfaces (drag-to-reprioritize, config editors, prompt tuners), anything with diagrams or side-by-side comparisons.

**Stay in Markdown for:** short terminal answers, commit messages, CLAUDE.md / agent instructions, README and contributor docs that go into version control (HTML diffs are noisy — this is the format's biggest downside), files I will edit by hand.

**Plans default to a file, not in-chat plan mode.** When I ask for a plan, write it to disk (HTML for anything substantial; Markdown only if it'll be version-controlled). I want to be able to come back to it across sessions.

**Rules of thumb:**
- For tuning/triage/config artifacts, include real interactivity (sliders, drag-and-drop, live preview) and **always end with an export button** (copy-as-JSON, copy-as-Markdown, copy-as-prompt) so output can flow back into Claude Code.
- After writing the file, offer to `open <file>.html` so I can view it.
- Don't double-emit a Markdown twin "just in case" — pick one.
- This is a default bias, not a mechanical rule. If Markdown genuinely fits better, use it.

## Git & pull requests

**Commits:** Conventional format — `<type>(<scope>): <subject>` where type is one of `feat | fix | docs | style | refactor | test | chore | perf`. Subject ≤ 50 chars, imperative mood ("add" not "added"), no trailing period. Small change → one-line commit. Complex change → add body explaining what/why (72-char wrap), reference issues. Keep commits atomic — one logical change per commit; split if you're addressing multiple concerns. Only commit when I explicitly ask.

**Pull requests:** When I ask for a PR message, check for `.github/pull_request_template.md` in the repo. If it exists, build the PR description on top of that template and output the result to a file named `pr.md`. If the template doesn't exist, **stop and ask me** how I want the PR structured rather than guessing a format.
