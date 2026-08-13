---
name: onboarding
description: First-day orientation for a new developer joining the project. Maps the repo structure, explains active rules and skills, and walks through the first-task checklist. Use when a dev says "I'm new", "just joined", "first PR", "how do I get started", "orient me", "new to this repo", "set me up", "what do I need to know", "I just cloned this", "walk me through the project", "onboard me", "getting started", "onboarding".
disable-model-invocation: true
---

# Project Onboarding

## Step 1 — Understand the repo structure

Run these in parallel:

```bash
git log --oneline -10          # recent work — what's been happening
git branch -a                  # branches in flight
ls -la                         # root layout (PowerShell: Get-ChildItem -Force)
cat README.md 2>/dev/null || echo "No README found"   # PowerShell: if (Test-Path README.md) { Get-Content README.md } else { "No README found" }
```

Then read:
- `AGENTS.md` or `.cursor/AGENTS.md` if present — AI agent instructions specific to this project
- `.cursor/rules/` — active Cursor rules (what the AI will and won't do here)
- Any `CONTRIBUTING.md` — team conventions

Report back: what the project does (one sentence), the main directories, and any rules or conventions you spotted.

## Step 2 — Verify your local setup

```bash
git config user.name
git config user.email
git remote -v
git status
```

Flag if:
- `user.name` or `user.email` is not set — commits will be anonymous
- There is no `origin` remote — pushes will fail silently
- There are uncommitted changes from a previous developer's work

## Step 3 — Understand the branching model

Check if the repo has branch protection by looking for:
- `.github/` directory (GitHub Actions / branch rules)
- A `CONTRIBUTING.md` section on branching

Tell the user:
- Never commit directly to `main` or `master`
- Branch naming: `feature/<what>`, `fix/<what>`, `chore/<what>`, `docs/<what>`
- Create your first branch now: `git checkout -b feature/<your-task-description>`

## Step 4 — Know your tools

These skills are available to you in this project. Use them by typing their name in Cursor:

| Skill | When to use |
|-------|-------------|
| `pre-commit-check` | Before every commit — catches secrets, debug code, bad messages |
| `commit-message` | When you're unsure how to phrase a commit |
| `pr-summary` | Before opening a PR — generates the description |
| `pr-review-canvas` | When reviewing someone else's PR |
| `deslop` | After a long AI session — removes noise from generated code |
| `document-this` | When asked to document a function or module |
| `handoff` | End of day or before switching tasks |

## Step 5 — First-PR checklist

Before you open your first pull request:

- [ ] Branch is off `main`/`master`, not off another feature branch
- [ ] `git diff main...HEAD` — confirm only your intended changes are included
- [ ] Ran `pre-commit-check` on every commit
- [ ] PR is focused on one thing — if you fixed two bugs, open two PRs
- [ ] PR description explains **why** the change exists, not just what it does
- [ ] No `console.log`, `print(`, `debugger`, or `TODO` left in production code
- [ ] No `.env` or secrets staged

## What to ask your team lead before starting

1. "Which ticket should I pick up first?"
2. "Is there a local dev setup doc or a `docker-compose` I should run?"
3. "Who reviews PRs for this area of the codebase?"
4. "What does done look like for this team — tests, docs, both?"
