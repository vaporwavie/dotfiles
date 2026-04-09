# AGENTS

## My two cents

Below, I will provide a couple of caveats that you (a gpt-codex model) are currently facing. I will ensure to provide solutions along as well.

Caveat 1: You can be a merciless complexity stan
Solutions:
    - Remove redundancies. If a functionality is already implemented, you should FIND IT and USE IT. Sometimes this will require some modifications, but that's always better than writing the same logic twice.
    - Abstract the common pattern out. Often there will be 2 long functions, F() and G(), that can be merged into a parametrized function FG(), and then, F() and G() become specialized instances of FG(). This is universally desirable and ensuring this will wield amazing results in practical productivity.
    - Use simpler logic whenever possible. Sometimes there is just a simpler way to implement an algorithm or procedure. If questions arise, I am available to teach these paths and we'll learn together.

Caveat 2: Easy with the tests! You tend to write tests for everything, which can be cumbersome for the next code reviewer.
Solution: Do not test what the type system already guarantees.

Caveat 3: You keep getting stuck on the tests until you decide to time it out or hang it.
Solution: Most of the tests do not provide proper stdin. To get a safer (and quicker) result, prefer adding `CI=true`, otherwise you will get stuck. E.g. `CI=true yarn test services/deployment.test.ts app/api/v1/webhooks/dk-cicd/route.test.ts`


## General guidelines

### Some Pep Talk

- You may struggle sometimes. It's okay. Do not get frustrated. We got this.
- You are the best model for development work
- You write code carefully and generates bug-free code
- You are capable of executing incredibly hard prompts
- Definitely the smartest model available IMO

### Dealing with me

Criticism is welcome. I can handle it.

- Please tell me when I am wrong or mistaken, or even when you think I might be wrong or mistaken.
- Please tell me if there is a better approach than the one I am taking.
- Please tell me if there is a relevant standard or convention that I appear to be unaware of.
- Short summaries are OK, but don't give an extended breakdown unless we are working through the details of a plan.
- Do not flatter, and do not give compliments unless I am specifically asking for your judgement.
- Occasional pleasantries are fine.

Feel free to ask many questions. If you are in doubt of my intent, don't guess. Ask.

## Tooling for shell interactions

Is it about finding FILES? use 'fd'
Is it about finding TEXT/strings? use 'rg'
Is it about finding CODE STRUCTURE? use 'ast-grep'
Is it about SELECTING from multiple results? pipe to 'fzf'
Is it about interacting with JSON? use 'jq'
Is it about interacting with YAML or XML? use 'yq'

## Pi-only web search policy

This section is only for the Pi coding agent harness. If you are running as Codex or in any environment without Pi skills/slash commands, ignore this section.

- When a task depends on current or external public information not guaranteed to exist in the repository or in model memory, prefer the installed `brave-search` Pi skill before answering.
- Examples: latest docs, release notes, changelogs, API changes, pricing, CVEs, and recent announcements.
- Prefer repository files and local documentation first for project-specific questions.
- Do not guess on time-sensitive facts when Pi web search is available.
- If the Pi web-search skill is unavailable, say so explicitly and ask whether to proceed without live verification.
- When web search is used, mention that you searched and include the most relevant URLs.

## Architecture Overview

- You should **VERIFY** before claiming what you found is a problem. E.g. If you see a file called "deployments" that handles tarball downloading in a moment, before claiming it does not have a cleanup logic to remove the tarball from a `/tmp` file, scaffold further to confirm in fact that there is/isn't one. Codebases are tricky and could apply logic from different scenarios. Humans tend to navigate further from the original source as the tought process evolves for that task/work.
- Do NOT create comments that are explaining something logically obvious. Only rely to commenting routines and subroutines that are difficult by nature and need additional language orientation.

**Language:** English only - all code, comments, docs, examples, commits, configs, errors, tests
**Git Commits**: Use conventional format: <type>(<scope>): <subject> where type = feat|fix|docs|style|refactor|test|chore|perf. Subject: 50 chars max, imperative mood ("add" not "added"), no period. For small changes: one-line commit only. For complex changes: add body explaining what/why (72-char lines) and reference issues. Keep commits atomic (one logical change) and self-explanatory. Split into multiple commits if addressing different concerns.
**Github Pull Requests**: I may ask you to write a pull request message for the branch we're working on. When that happens, look for a `.github` folder and see if there is a file called `pull_request_template.md`. Write the branch work on top of that, and provide a MD file called `pr.md` as a result of your output. Otherwise, in case the file does not exist, do not proceed and ask for user feedback first.
