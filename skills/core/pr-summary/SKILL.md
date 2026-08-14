---
name: pr-summary
description: Create a pull request with a clear title, summary, and test plan using the gh CLI. Use when the user asks to open a PR, create a pull request, "push and PR", "submit for review", "raise a PR", "write PR description", "write the PR", "I'm ready to merge", "open a pull request", "create PR", "submit my work". Analyzes all commits in the branch, not just the latest.
disable-model-invocation: true
---

# 📬 PR Summary

## Run these in parallel first
1. `git status` — confirm no uncommitted changes.
2. `git log [base-branch]...HEAD --oneline` — all commits that will be in the PR.
3. `git diff [base-branch]...HEAD` — full diff for context.
4. `git status` — check if branch tracks a remote (determines if push is needed).

Use `main` or `master` as the base branch unless the user specifies otherwise.

## Analyze ALL commits (not just the latest)
Identify: what changed, why it changed, and what a reviewer needs to verify.

## Draft
- **Title**: imperative, present tense, ≤60 chars, no trailing period.
- **Summary**: 1–3 bullet points — what and why.
- **Test plan**: checklist of steps to verify the change works.

## Create the PR
```bash
# Push if not already on remote
git push -u origin HEAD

# Create PR
gh pr create --title "your title" --body "$(cat <<'EOF'
## Summary
- bullet

## Test plan
- [ ] step
EOF
)"
```

```powershell
# PowerShell (no heredoc support — use a here-string instead):
$body = @'
## Summary
- bullet

## Test plan
- [ ] step
'@
gh pr create --title "your title" --body $body
```

Return the PR URL when done.

## Do not
- Force-push unless the user explicitly asks.
- Merge or delete branches without being asked.
- Summarize work you have not read — read the full diff first.

## Gotchas
- `git log [base]...HEAD` diffs against the local copy of the base branch — if it hasn't been fetched recently, the commit range can be stale or wrong. Run `git fetch origin` first when in doubt.
- If the branch has no upstream yet, `git push -u origin HEAD` creates a new remote branch as a side effect — confirm that's intended before running it, don't just run it because the PR needs a remote ref.
- `gh pr create` fails outright if `gh auth status` isn't authenticated — check that before drafting the PR body, not after.
