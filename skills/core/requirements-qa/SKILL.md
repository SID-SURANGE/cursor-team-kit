---
name: requirements-qa
description: Quality-check requirements, BRD, discovery, and understanding documents for invented content, open questions, and source conflicts. Use when working in docs/, requirements/, or BRD files; when the user asks to review a discovery question list, update a master doc, check a requirements file, or verify accuracy against source PDFs. Also use when asked "did we capture this correctly?" about any requirements document.
disable-model-invocation: true
---

# 📋 Requirements QA

## Principles
- The source-of-truth file is declared in `.cursor/rules/project-context.mdc` or `AGENTS.md`. Read it first.
- Do not invent missing requirements. Surface gaps as open questions.
- When source documents conflict, call out the conflict explicitly — do not silently resolve it.
- Do not update the master doc without being asked. Only report findings.

## Steps

1. **Identify sources** — find source PDFs, BRDs, emails, or meeting notes, and the master/understanding doc.
2. **Cross-reference** — every claim in the master must trace to a source doc, or be marked as an assumption.
3. **Flag findings** using the output format below.
4. **Surface open questions** — list any that remain unanswered in the source material.

## Flag categories

| Category | Meaning |
|----------|---------|
| `[invented]` | Claim in master doc with no source citation |
| `[conflict]` | Two source docs disagree on the same point |
| `[open]` | Question not yet answered in any source |
| `[duplicate]` | Same content repeated across multiple docs unnecessarily |
| `[stale]` | Content that existed in an old version but no longer matches current source |

## Output format
```
[invented]  §3.2 — "daily batch at midnight" has no source in any PDF
[conflict]  §4 vs PDF-2 p.8 — field count differs (75 vs 72 fields)
[open]      §8.1 OD-3 — Cognida role/ownership still unresolved
[duplicate] understanding.md §2 repeats master.md §3.1 verbatim
```

Report all findings before making any edits.

## Gotchas
- If no source-of-truth file is declared anywhere (`.cursor/rules/project-context.mdc`, `AGENTS.md`), do not guess which doc is authoritative — ask. Picking the wrong one silently propagates wrong "invented" flags.
- Scanned/image-only source PDFs may extract as empty or garbled text depending on the tool used to read them — treat a suspiciously short or nonsensical extraction as "unable to verify," not as "no source found."
- A claim can be technically traceable to a source doc but still wrong if the source itself was superseded by a later document — check document dates, not just presence of the claim.
