---
name: commit-message
description: Enforce Conventional Commits discipline — infer type (feat/fix/refactor/…) and scope from the staged diff and changed file paths, and produce a structured `type(scope): subject` message. Goes beyond basic AI commit generation by applying CC rules and scope inference. Triggered by "write a commit message", "what should I commit this as", "help me commit", "what should my commit say", "commit msg", "suggest a commit message", "how do I phrase this commit", "write a good commit", "commit-message".
---

# ✏️ Skill: commit-message

## Purpose
Produce a structured, Conventional Commits-compliant commit message from the staged diff — not a free-form summary. Separate from `pre-commit-check` (which audits the staged diff for issues; this writes the message after the audit passes).

## Trigger phrases
- "write a commit message"
- "what should I commit this as"
- "commit-message"
- "generate a commit message"
- "what's a good commit message for this"

## Steps

### 1. Read the staged diff and recent history
```bash
git diff --cached          # staged changes — the primary input
git log --oneline -10      # recent messages — infer repo's convention and scope patterns
```

### 2. Infer the type

| Type | Use when |
|------|----------|
| `feat` | New capability visible to a user or caller |
| `fix` | Corrects a defect or wrong behaviour |
| `refactor` | Restructures code without changing observable behaviour |
| `docs` | Changes to documentation only |
| `test` | Adds or fixes tests |
| `chore` | Build scripts, CI config, dependency bumps, tooling |
| `perf` | Measurable performance improvement |
| `style` | Formatting, whitespace — no logic change |

Pick the single most accurate type. If the diff spans multiple types, pick the dominant one and note the others in the body.

### 3. Infer the scope

Derive scope from the primary directory or module affected:

| Changed path | Scope example |
|---|---|
| `src/auth/` | `auth` |
| `skills/core/commit-message/` | `commit-message` |
| `hooks/git-guard.sh` | `hooks` |
| Root-level config only | omit scope |

Use the repo's recent log as a reference — match existing scope conventions if present.

### 4. Write the subject line

```
type(scope): imperative description of what changed
```

Rules:
- Imperative mood: "add", "fix", "remove" — not "added", "fixes", "removing"
- ≤72 characters total (type + scope + colon + space + description)
- No period at the end
- Lowercase after the colon

### 5. Write the body (if needed)

Add a body when:
- The why is not obvious from the subject
- The diff spans multiple concerns
- There is a breaking change

Separate subject from body with a blank line. Wrap body at 72 characters.

For breaking changes, append:
```
BREAKING CHANGE: <what changed and how callers must adapt>
```

### 6. Output

Present the commit message in a code block, ready to copy:

```
type(scope): subject

Optional body explaining the why, not the what.
```

Then ask: "Ready to commit with this message, or would you like to adjust it?"

Do not run `git commit` — that is the user's decision.

## Output
A single commit message block. No explanation unless the type choice is non-obvious.

## Notes
- If the staged diff is empty, say so and stop.
- If the diff is large and spans unrelated concerns, flag it: "This diff touches X and Y — consider splitting into two commits."
- Do not use `git commit -m` or make the commit. Write the message only.

## Gotchas
- Never fall back to unstaged changes when the staged diff is empty — that produces a message for content the user hasn't actually chosen to commit.
- When the diff spans many unrelated top-level directories, don't force a single scope onto it — say the scope is ambiguous and let the user pick, or recommend splitting the commit.
- `git log --oneline -10` on a very young repo (first few commits) may not have enough history to reliably infer a scope/type convention — say so rather than pattern-matching on 1–2 examples.
