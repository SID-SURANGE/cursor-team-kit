---
name: minimal-diff-review
description: Review a set of code or document changes for scope creep, convention drift, and quality issues following team standards. Use when the user asks to "review my changes", "check the diff", "look at what I changed", "is this good to go", "sanity check my code", "does this look right", "review before I push", "quick review", or before a PR is created. Also use proactively after large edits to check nothing went out of scope.
disable-model-invocation: true
---

# 🔎 Minimal Diff Review

## Get the diff
```bash
git diff          # unstaged
git diff --cached # staged
git diff HEAD     # both
```

Read original files at changed lines for context before judging.

## Flag these categories

| Category | Flag if |
|----------|---------|
| **Scope creep** | Files touched that are unrelated to the stated task |
| **Convention drift** | Naming, imports, or style diverge from surrounding code |
| **Unrequested abstractions** | New classes, helpers, or layers added without being asked |
| **Debug code** | `console.log`, `print(`, `debugger`, `breakpoint()`, `TODO` in changed lines |
| **Doc drift** | Public API or interface changed but no corresponding doc update |
| **Test gap** | Behavior-changing code with no test added or updated (flag only, not block) |

## Output format
```
[scope-creep]   src/utils.py:45 — touches unrelated date formatter
[convention]    api/routes.ts:12 — uses snake_case; surrounding code uses camelCase
[debug]         app/main.go:88 — print statement left in
```

## Rules
- Flag issues only. Do not silently fix or revert changes.
- Do not suggest rewrites unless the user asks for them.
- Severity is implied by category — do not add emoji or color ratings.

## Gotchas
- A rename that Git can't detect as a rename (heavy edits alongside the move) shows as a full delete + add — don't flag it as scope creep without checking `git diff -M` first.
- `git diff` alone misses already-staged changes and `git diff --cached` alone misses unstaged ones — use `git diff HEAD` when the user means "everything I've changed," not just one of the two.
- On a very large diff, reading every changed file in full can blow the context budget — scope to the files the diff stat shows as most-changed first, and say what was skipped.
