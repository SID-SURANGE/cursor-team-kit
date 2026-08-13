---
name: sync-docs-after-edit
description: After local changes or a commit, scan all .md files in the repo and flag any that are stale or contradicted by the changes. Triggered by "sync docs", "check if docs are up to date", "update docs after my changes", "did my change break any docs?", "are the docs current", "update the readme", "docs out of date", "docs stale", "update documentation".
---

# 📝 Skill: sync-docs-after-edit

## Purpose
Keep documentation honest after local edits or commits. Distinct from `sync-docs-after-git-pull` (which fires after receiving remote changes) — this skill reacts to **what you just changed locally**.

## Trigger phrases
- "sync docs"
- "check if docs are up to date"
- "update docs after my changes"
- "did my change break any docs?"
- "sync-docs-after-edit"

## Steps

### 1. Identify what changed
```bash
# Uncommitted changes
git diff --name-only

# Last commit
git diff --name-only HEAD~1..HEAD

# Staged but not committed
git diff --cached --name-only
```

Collect the full set of changed source files. Exclude `.md` files themselves from the "changed source" list — they are the targets, not the triggers.

### 2. Discover all documentation files
```bash
# List tracked markdown files — cross-platform by construction (git ships
# identically on macOS/Linux/Windows), and naturally excludes .git/node_modules/
# vendor/.venv as long as they're gitignored, with no -not -path gymnastics needed.
git ls-files '*.md'

# If newly-added (untracked) docs should also be in scope, add:
git ls-files --others --exclude-standard '*.md'
```
This only covers files git knows about (tracked, plus untracked if you add the
second command) — which is the correct scope for a "sync docs" pass, since a
doc that isn't even staged for commit isn't part of "what you just changed."

If you're truly outside a git repo, use the PowerShell-native equivalent instead:
```powershell
Get-ChildItem -Recurse -Filter *.md | Where-Object { $_.FullName -notmatch '\\(\.git|node_modules|vendor|\.venv)\\' }
```
(GNU `find -not -path` has no native Windows equivalent — the `find.exe` bundled
with `cmd.exe` is a completely different, incompatible tool.)

### 3. For each .md file, assess relevance

Read the `.md` file and the changed source files. Assess:

| Question | If yes → |
|----------|----------|
| Does the doc reference a function, class, or API that was renamed or removed? | **Needs update** |
| Does the doc describe a workflow or command that no longer works as written? | **Needs update** |
| Does the doc include example code that is now incorrect? | **Needs update** |
| Does the doc describe a config option that was added or changed? | **Needs update** |
| Is the doc entirely unrelated to the changed files? | **Not affected** |
| Is the doc correct and consistent with the changes? | **Up to date** |

### 4. Report per-file verdicts

Always include `README.md` and `CHANGELOG.md` as explicit rows — even if they appear unaffected. These are the two docs most likely to drift silently.

```
Documentation sync report
Changed source files: <list>

| Doc file | Verdict | Notes |
|----------|---------|-------|
| README.md | Needs update | Quick Start references `DB_URL` — now `DATABASE_URL` |
| CHANGELOG.md | Needs entry | No entry yet for changes in this diff |
| docs/api.md | Needs update | References `getUser()` which was renamed to `fetchUser()` |
| docs/setup.md | Up to date | |
```

### 5. Apply updates (if instructed)
If the user says "update them" or "fix the docs":
- For each file marked **Needs update**: make the minimal edit to bring it in line with the code changes.
- Do not rewrite docs wholesale — only fix what's factually stale.
- After editing, re-run the assessment for the updated files to confirm they're now clean.

### 6. Final confirmation
After all updates:
```
All docs synced.
Updated: <list of files changed>
No-change: <list confirmed up to date>
```

## Output
A per-file verdict table, plus optional edits if the user confirms.

## Notes
- If `CHANGELOG.md` exists, always flag it as a candidate — new changes often warrant a changelog entry.
- If `README.md` has a "Quick start" or "API" section, always read it against the changed source.
- Do not update `CHANGELOG.md` automatically — propose the entry and let the user confirm.
