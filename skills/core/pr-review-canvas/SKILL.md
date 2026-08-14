---
name: pr-review-canvas
description: Group PR changes by purpose, flag risky sections, and produce a reviewer map so the reader doesn't parse raw diff. Triggered by "review canvas", "map this PR", "help me review this PR", "understand this PR", "what does this PR change", "walk me through this PR", "review this diff", "what should I focus on in this PR", "pr-review-canvas".
disable-model-invocation: true
---

# 🗺️ Skill: pr-review-canvas

## Purpose
Turn an unstructured diff into a structured review map: what changed, why it matters, where to look first, and what to be careful about. Helps reviewers focus attention rather than read everything.

Note: Cursor's own official `cursor-team-kit` plugin ships a skill with this same name. This version outputs a plain-text/markdown reviewer map printed to chat (optionally saved as `PR_CANVAS.md`) rather than an interactive HTML walkthrough — no rendering step, works the same in any client that can display markdown.

## Trigger phrases
- "review canvas"
- "map this PR"
- "pr-review-canvas"
- "give me a PR overview"
- "structure this PR for review"

## Steps

### 1. Fetch the diff
```bash
# If PR number is known:
gh pr diff <number>

# If on the branch:
git diff main...HEAD --stat
git diff main...HEAD
```

Also fetch the PR description:
```bash
gh pr view <number>
```

### 2. Categorize every changed file
Assign each file to one category:

| Category | What it means |
|----------|---------------|
| **Feature** | New user-visible behaviour |
| **Fix** | Bug correction |
| **Refactor** | Structure change, no behaviour change |
| **Config** | Environment, build, or tooling config |
| **Test** | Test-only changes |
| **Infra** | CI, Docker, deployment |
| **Docs** | Documentation or comments only |

### 3. Build the reviewer map

```
## PR Canvas: <PR title>

### Summary
<2-3 sentences: what this PR does and why>

### Change map
| File / Area | Category | Lines ±  | Risk | Reviewer note |
|-------------|----------|----------|------|---------------|
| src/foo.ts  | Feature  | +120/-30 | Med  | Core logic change — review carefully |
| tests/foo.test.ts | Test | +80 | Low | Covers happy path + 2 edge cases |
| config/env.example | Config | +3 | Low | New env var — check deployment runbook |

### Risk sections (read these first)
1. <file>:<line-range> — <reason it's risky>
2. ...

### What's NOT in this PR (but might be expected)
- <missing tests for X>
- <no migration for schema change>
- ...

### Suggested review order
1. <file or area to read first>
2. ...
```

### 4. Flag concerns
Automatically flag:
- Files changed without accompanying tests (for non-trivial logic).
- Config changes with no documentation update.
- Large single files (>300 lines changed) — suggest splitting if not already merged.
- Direct changes to `main`/`master` branch protection files.
- Secrets-adjacent files (`.env`, credential configs).

### 5. Output
Print the reviewer map to chat. If the user asks, also write it as `PR_CANVAS.md` in the repo root (gitignored by default).

## Output
Structured reviewer map with change categorization, risk flags, and suggested review order.

## Gotchas
- `gh pr diff <number>` and `gh pr view <number>` need `gh` authenticated against the right repo — if `gh auth status` fails, fall back to local `git diff` against the base branch and say the PR metadata (description, comments) is unavailable rather than silently omitting it.
- Line-count-based risk ("Med"/"High") is a heuristic, not a real risk signal — a 5-line change to auth middleware is higher risk than a 200-line change to a test fixture. Weigh what the file does, not just its diff size.
- Renamed/moved files can appear as large deletes+adds in the stat — check for a rename before categorizing them as a big risky change.
