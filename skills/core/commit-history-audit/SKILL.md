---
name: commit-history-audit
description: Audit a branch's full commit history for commit hygiene — WIP commits, squash candidates, merge commit policy violations, subject length, and optional convention compliance — before opening a PR. Triggered by "audit my commits", "check commit history before PR", "are my commits clean", "commit-history-audit".
---

# Skill: commit-history-audit

## Purpose

Catch commit hygiene problems before a PR reviewer does. Writing a good commit is covered by `commit-message`; this skill audits what's already on the branch — the full history from the point it diverged from the base branch — and produces a compliance report with specific remediation steps.

Convention detection is self-calibrating: the skill reads the repo's own commit history to determine what standards are in use before checking anything. It never imposes Conventional Commits on a repo that doesn't already use it.

## Trigger phrases

- "audit my commits"
- "check commit history before PR"
- "are my commits clean"
- "commit-history-audit"
- "review my branch commits"
- "check my git history"

## Steps

If your environment supports spawning a sub-agent (a background/isolated agent that returns only its final output to the main conversation), delegate steps 1-5 to it — the full commit history pull and per-commit analysis can be long on active branches, and only the finished report from step 5 needs to land in the main thread. If no sub-agent capability is available, run steps 1-5 inline as normal.

### 1. Determine the base branch and divergence point

```bash
# Identify the base branch (try common names in order)
git remote show origin 2>/dev/null | grep "HEAD branch" | awk '{print $NF}'
# PowerShell equivalent: (git remote show origin 2>$null | Select-String 'HEAD branch').ToString().Split()[-1]
# Fallback: check for main, master, develop
git branch -r | grep -E "origin/(main|master|develop)" | head -1
# PowerShell equivalent: (git branch -r | Select-String 'origin/(main|master|develop)' | Select-Object -First 1)
```

```bash
# Find commits on this branch not on the base branch
git log --oneline main..HEAD        # replace 'main' with the detected base branch
```

If the branch has no divergence (is at HEAD of base), say so and stop — nothing to audit.

### 2. Collect full commit data

```bash
git log main..HEAD --pretty=format:"%H|%s|%an|%ae|%ai|%P" --no-merges
```

Also collect any merge commits separately:

```bash
git log main..HEAD --merges --oneline
```

### 3. Detect the repo's commit convention

Before checking anything, read the base branch history to understand what this repo actually does:

```bash
git log origin/main -50 --pretty=format:"%s" 2>/dev/null | head -50
# PowerShell equivalent: git log origin/main -50 --pretty=format:"%s" 2>$null | Select-Object -First 50
```

Classify the repo into one of three modes:

| Mode | Signal | What to enforce |
|------|--------|-----------------|
| **Conventional Commits** | ≥40% of recent base commits match `type:` or `type(scope):` pattern | All CC rules apply |
| **Ticket-prefixed** | ≥30% of recent base commits start with `[JIRA-123]`, `#42`, or similar | Ticket ref rules apply; CC rules do not |
| **Free-form** | Neither pattern detected | Only universal hygiene rules apply (WIP, length, merge commits) |

Record the detected mode and state it at the top of the audit report.

### 4. Audit each commit against these rules

For every commit (excluding merge commits for rules 1–4, analysing merges in rule 5):

#### Rule 1 — Commit convention compliance *(conditional on detected mode)*

**Conventional Commits mode only:**

Subject must match: `^(feat|fix|refactor|docs|test|chore|perf|style|ci|build|revert)(\(.+\))?: .+`

Flag: subject does not match — label **[NO-CONVENTION]**

**Ticket-prefixed mode only:**

Subject must start with a ticket reference matching the detected pattern (e.g. `PROJ-123`, `#42`).

Flag: subject has no ticket reference — label **[NO-TICKET]**

**Free-form mode:** Rule 1 does not apply. Skip it.

#### Rule 2 — Subject line length

Subject ≤ 72 characters. Applies in all modes.

Flag: exceeds limit — label **[TOO-LONG]** with current character count

#### Rule 3 — Imperative mood (heuristic)

Subject must not start with a past-tense or gerund verb. Applies in all modes.

Common violations: starts with "added", "adding", "fixed", "fixing", "updated", "updating", "changed", "changing", "removed", "removing"

Flag: detected past/gerund — label **[PAST-TENSE]**

#### Rule 4 — WIP / draft commits

Subject contains: `wip`, `WIP`, `fixup!`, `squash!`, `temp`, `tmp`, `do not merge`, `dnm`. Applies in all modes.

Flag — label **[WIP]**

#### Rule 5 — Merge commits (squash/rebase repos only)

Check the base branch merge style:

```bash
git log origin/main -20 --merges --oneline
```

If base branch has zero merge commits → repo uses squash or rebase strategy.

Flag any merge commit on the branch — label **[MERGE-COMMIT]**. Skip this rule if the base branch itself contains merge commits (the repo allows them).

#### Rule 6 — Single-purpose signal *(advisory only, all modes)*

If the branch touches clearly unrelated concerns across commits (e.g. UI changes mixed with database migrations), note this as a signal for the reviewer. Not a violation — never produces a flag in the table.

### 5. Produce the audit report

Output a structured report in this format:

```markdown
## Commit History Audit — <branch-name>

Convention mode detected: Conventional Commits | Ticket-prefixed (PROJ-NNN) | Free-form
Base branch: <main|master|develop>
Commits audited: <N>
Merge commits found: <N>

### Results

| # | Short SHA | Subject | Issues |
|---|-----------|---------|--------|
| 1 | abc1234   | feat: add login page | ✅ |
| 2 | def5678   | Added user model | [NO-CONVENTION] [PAST-TENSE] |
| 3 | ghi9012   | wip fixes | [WIP] [NO-CONVENTION] |

### Violations Summary

**[NO-CONVENTION]** — 2 commits
**[PAST-TENSE]** — 1 commit
**[WIP]** — 1 commit

### Compliance Score

X / N commits clean  →  <PASS | NEEDS CLEANUP>

Pass threshold: all commits must be violation-free for a PASS.

### Remediation

For each violation, provide the specific fix:

**def5678 — "Added user model"**
Suggested rewrite: `feat(auth): add user model`
To amend: `git rebase -i main` and reword this commit.

**ghi9012 — "wip fixes"**
This commit should be squashed into its predecessor or given a meaningful message.
To squash: `git rebase -i main` and mark this commit `squash` or `fixup`.
```

### 6. Offer next steps

After the report, ask:

> "Would you like me to generate the interactive rebase commands to fix these, or open the PR as-is with a note about the history?"

Do not run `git rebase` automatically — that is a destructive operation requiring user confirmation.

## Output

- A markdown audit table with per-commit flags
- A violations summary with counts
- A compliance score (PASS / NEEDS CLEANUP)
- Specific remediation steps for each failing commit

## Notes

- If the branch has more than 50 commits, warn the user: "This is a large branch. Auditing the last 50 commits — pass `--all` to audit further back."
- Commits by bots (email contains `[bot]` or `noreply`) are excluded from the audit.
- This skill audits; it does not rewrite. All git history changes require explicit user action.
- Works alongside `pre-commit-check` (which audits staged changes before a single commit) and `pr-summary` (which creates the PR after history is clean).
