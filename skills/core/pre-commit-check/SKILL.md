---
name: pre-commit-check
description: Check staged changes before creating a git commit. Reviews the diff for secrets, unrelated changes, debug code, oversized PRs, and matches the repo's commit message style. Use when the user says "commit", "create a commit", "git commit", "commit this", "commit my changes", "ready to commit", "safe to commit", "check my changes", "stage and commit", "push my work", or "I'm done with this task".
disable-model-invocation: true
---

# 🔍 Pre-Commit Check

## Run these in parallel
1. `git status` — list staged and unstaged files.
2. `git diff --cached` — full staged diff.
3. `git log --oneline -5` — recent commit messages to infer style.
4. `git diff --cached --shortstat` — line and file counts for size check.

## Check the staged diff for

| Issue | Action |
|-------|--------|
| `.env`, `*.key`, `credentials.*`, `*secret*` staged | Stop. Warn user. Do not commit. |
| Secrets or tokens in changed lines | Stop. Warn user. |
| Changes to files unrelated to the stated task | Flag — do not auto-unstage |
| Debug code (`console.log`, `print(`, `debugger`, `breakpoint()`) | Flag |
| Nothing staged | Do not create an empty commit. Tell the user. |
| >400 lines changed or >10 files touched | Flag as oversized — suggest splitting by concern |
| Multiple unrelated concerns in one diff | Flag — name each concern and suggest separate commits |

## Commit message

### Format
```
<type>: <subject>          ← max 72 chars, imperative present tense

[optional body]            ← wrap at 72 chars, explains WHY not WHAT

[optional footer]          ← e.g. Closes #123, Co-authored-by: ...
```

### Type prefixes (use the project's convention if one exists)
| Type | When to use |
|------|-------------|
| `feat` | New user-visible feature |
| `fix` | Bug fix |
| `refactor` | Code restructure, no behaviour change |
| `test` | Adding or updating tests |
| `docs` | Documentation only |
| `chore` | Tooling, config, dependencies |
| `perf` | Performance improvement |

### Subject line rules
- Imperative present tense: "add user auth" not "added" or "adding"
- No trailing period
- No emoji unless the project convention uses them
- ≤72 characters — hard limit

### Body (include when the change is non-obvious)
- Explain **why** the change was made, not what the diff shows
- Mention alternatives considered if the choice is non-obvious
- Reference issue numbers: `Closes #42`, `Refs #17`

### What to avoid
- "WIP", "fix stuff", "changes" — not searchable or reviewable
- Giant commits mixing unrelated changes — split them
- Committing without staged content

### Always pass the message via HEREDOC (per `git-safety` rule)
```bash
git commit -m "$(cat <<'EOF'
feat: add user authentication

Replaces the previous session-token approach with JWT.
Closes #42
EOF
)"
```

```powershell
# PowerShell (no heredoc support — use a here-string instead):
$msg = @'
feat: add user authentication

Replaces the previous session-token approach with JWT.
Closes #42
'@
git commit -m $msg
```

## After commit
Run `git status` to confirm success before reporting done.

## Gotchas
- Secret detection here is pattern/filename based — it will miss a secret pasted directly into application code that doesn't match `*.env`/`*key*`/`*secret*`. Read the actual diff content, not just filenames.
- `git diff --cached --shortstat` reports nothing if nothing is staged — check `git status` first, or an empty diff silently passes every check.
- Binary files show no line-level diff, so debug-code and secret greps produce false negatives on them — flag binaries added to the diff separately.
