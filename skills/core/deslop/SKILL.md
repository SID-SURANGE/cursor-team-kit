---
name: deslop
description: Strip redundant comments, dead variables/imports, and defensive try/catches wrapping trivially safe operations. Triggered by "deslop", "clean this up", "remove dead code", "clean up AI-generated code", "remove noise", "tidy this", "remove unnecessary code", "clean the output", "simplify this", "remove boilerplate".
---

# 🧹 Skill: deslop

## Purpose
Remove low-value noise from code: comments that narrate what the code already says, unused variables and imports, and try/catch blocks that add no recovery logic. Makes the codebase easier to read and maintain.

## Trigger phrases
- "deslop"
- "clean this up"
- "remove dead code"
- "strip unnecessary comments"
- "remove unused imports"

## Steps

### 1. Determine scope
- If the user points at a file or selection, scope to that.
- If no scope given, ask: "Which file or directory should I deslop?"
- Do not deslop the entire repo unsolicited.

### 2. Scan for slop categories

#### A. Narrating comments
Comments that restate what the code does with no additional insight:

```python
# Bad — obvious from the code
i = i + 1  # Increment i

# Bad — restates the function name
def get_user(id):
    # Get the user by ID
    return db.query(User, id)
```

Keep comments that explain *why* (non-obvious intent, trade-offs, constraints, workarounds).

#### B. Dead variables and imports
- Variables assigned but never read.
- Imports that are never referenced.
- Function parameters that are accepted but ignored (note: may be interface-required — flag, don't auto-delete).

#### C. Defensive try/catches with no recovery
```python
# Slop — try/except that only re-raises or swallows silently
try:
    x = int(value)
except:
    pass  # no recovery, no logging

# Also slop — wraps a trivially safe operation
try:
    name = obj.name
except AttributeError:
    name = None  # could just use: name = getattr(obj, 'name', None)
```

Keep try/catches that: log the error, transform the exception type, implement real recovery, or wrap genuinely unsafe I/O.

#### D. Commented-out code blocks
- Remove blocks of code that have been commented out.
- Exception: leave a comment if the block includes a TODO or a link to an issue explaining why it's disabled.

### 3. Apply changes
- Make minimal edits — only remove what's clearly slop.
- Do not refactor logic, rename variables, or restructure code in a deslop pass.
- If something is ambiguous (e.g. an import that might be used dynamically), leave it and note it.

### 4. Report

```
Deslopped: <filename>

Removed:
- <count> narrating comments
- <count> unused imports: <list>
- <count> dead variables: <list>
- <count> empty/pointless try/catches

Left in place (flagged for review):
- <item> — reason
```

## Output
Cleaned file(s) + a brief removal summary. No behaviour changes — only noise removal.

## Guardrails
- Never remove the only comment explaining a non-obvious algorithm or business rule.
- Never remove imports/variables without confirming they're unused (use static analysis or grep first).
- Never change logic — if a cleanup requires a logic decision, stop and ask.

## Gotchas
- Grep-based "unused import" detection is unreliable in dynamic languages — Python re-exports via `__all__`, JS/TS barrel files, and reflection-based lookups can all reference a symbol without a matching identifier appearing in a text search. Prefer the project's actual linter output when one exists; treat a plain grep as advisory only.
- A parameter that looks unused may be required by an interface, protocol, or callback signature the file doesn't show — check the call site or interface definition before flagging it as dead.
- A try/except that looks like a no-op recovery may exist specifically to suppress a known third-party library quirk — if the surrounding code or a comment hints at that, ask rather than strip it.
