---
name: document-this
description: Add why-only comments or docstrings to a function, class, or module. Writes comments that explain intent and constraints — not what the code does. Triggered by "document this function", "add comments", "write docstrings", "document-this".
---

# 📖 Skill: document-this

## Purpose
Add comments that carry information the code cannot. The "why" — the constraint, the invariant, the non-obvious tradeoff — is the only thing worth writing. What the code does is already in the code.

This skill enforces the discipline the `deslop` skill removes: do not write narrating comments that restate the code in English.

## Trigger phrases
- "document this function"
- "add comments"
- "write docstrings"
- "document-this"
- "add JSDoc"
- "add a docstring to this"
- "explain why this works this way"

## The rule

**Write a comment if and only if removing it would leave a future reader confused about WHY — not WHAT.**

| Write it | Skip it |
|---|---|
| Why this algorithm instead of the obvious one | What the loop does (the loop says it) |
| What invariant must hold when this is called | What the parameter means (the name says it) |
| Why this magic number (business rule, standard, bug workaround) | That the function returns a value |
| What breaks silently if you change the order | That this is a helper function |
| Which upstream bug this works around | That the class represents a user |

## Steps

### 1. Read the target

Read the function, class, or module the user pointed at. Do not infer scope — ask if unclear.

### 2. Identify comment-worthy facts

For each section of code, ask:
- Is there a non-obvious constraint? (call order, thread safety, size limit, encoding assumption)
- Is there a tradeoff the next person would re-litigate without context? (O(n²) that's fine because n < 50, a cache that must stay warm)
- Is there a workaround for an external bug, API quirk, or spec gap?
- Is there a business rule that looks like a magic number?

If none of the above apply to a section, write no comment for it.

### 3. Choose the format

| Language / context | Format |
|---|---|
| JavaScript / TypeScript (exported) | JSDoc `/** */` on the function/class |
| JavaScript / TypeScript (internal) | Single-line `//` above the relevant line |
| Python (public function/class) | Docstring `"""..."""` immediately inside |
| Python (internal) | `#` comment above the relevant line |
| Go | `//` comment on the exported symbol |
| Other | Match the file's existing comment style |

For JSDoc/docstrings on exported symbols, include:
- One sentence: why this exists (not what it does)
- `@param` lines only when the type or constraint is non-obvious
- `@returns` only when the return value has a non-obvious meaning or invariant
- `@throws` only when the caller must handle a specific error case

### 4. Write comments, not rewrites

- Touch only comments. Do not rename, reformat, or restructure any code.
- Place inline comments on the line they explain, or on the line above.
- Keep each comment short — one to two lines. If you need three, the code needs restructuring, not a comment.

### 5. Present for review

Show the diff (old → new) before applying. Say: "These comments explain the why — ready to apply?"

Do not apply until confirmed.

## Output
A minimal diff adding comments only. No logic changes.

## Example

**Before:**
```python
def retry(fn, n=3, delay=1.5):
    for i in range(n):
        try:
            return fn()
        except Exception:
            if i == n - 1:
                raise
            time.sleep(delay * (2 ** i))
```

**After (document-this applied):**
```python
def retry(fn, n=3, delay=1.5):
    # Exponential back-off: each retry waits 1.5× longer to avoid thundering-herd
    # on the upstream rate limiter, which resets on a fixed 2s window.
    for i in range(n):
        try:
            return fn()
        except Exception:
            if i == n - 1:
                raise
            time.sleep(delay * (2 ** i))
```

Note: the loop body itself needs no comment — it is self-evident.

## Gotchas
- Inferring "why" from the function name or body alone risks encoding a guess as fact — if the rationale isn't evident from the code itself (a linked issue, a commit message, an adjacent comment), check call sites or git blame before asserting a reason, or write the constraint you can verify ("must be called after X" — observable) instead of the motivation you can't ("because the API changed" — unverified).
- A "why" comment written before behavior is fully understood can encode a wrong belief that outlives the mistake — if the function is unclear even after reading it, say so and ask rather than guessing at intent.
