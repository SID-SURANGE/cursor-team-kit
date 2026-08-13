---
name: architecture-decision-records
inspired-by: "awesome-cursor-skills (github.com/spencerpauly/awesome-cursor-skills) — ADR workflow and template structure. No text copied. Original work."
description: Create or update an ADR file following the standard template (Context, Decision, Consequences). Triggered by "create an ADR", "document this decision", "write an ADR", "record this architectural decision", "I need to document why we chose", "adr", "log this design decision", "why did we pick this approach", "architecture-decision-records".
---

# 🏛️ Skill: architecture-decision-records

## Purpose
Capture significant architectural or design decisions in a lightweight, durable format. Prevents "why did we do it this way?" from being answered by archaeology. Useful for code repos, requirements repos, and consulting deliverables alike.

## Trigger phrases
- "create an ADR"
- "document this decision"
- "architecture-decision-records"
- "write an ADR for this"
- "record this design decision"
- "ADR"

## Steps

### 1. Determine the ADR directory
- Check if `docs/adr/`, `adr/`, or `decisions/` exists in the repo.
- If none exists, default to `docs/adr/` and create it.
- Check `.cursor/` or `AGENTS.md` for a project-specific ADR path override.

### 2. Assign a number
```bash
ls docs/adr/ | sort | tail -1    # PowerShell: Get-ChildItem docs/adr/ | Sort-Object | Select-Object -Last 1
```
Next ADR number = last number + 1. Zero-pad to 4 digits: `0001`, `0002`, etc.

### 3. Determine the status
Choose one:
- **Proposed** — under discussion, not yet accepted.
- **Accepted** — the decision has been made and is in effect.
- **Deprecated** — was accepted but is no longer relevant.
- **Superseded by ADR-XXXX** — replaced by a newer decision.

### 4. Draft the ADR

Filename: `docs/adr/<NNNN>-<kebab-case-title>.md`

```markdown
# ADR-<NNNN>: <Title>

**Date:** <YYYY-MM-DD>  
**Status:** <Proposed | Accepted | Deprecated | Superseded by ADR-XXXX>  
**Deciders:** <names or roles>

---

## Context

<What is the situation or problem that motivated this decision? Include constraints, forces, and relevant background. Be factual — no advocacy here.>

## Decision

<What was decided? State it clearly and directly. "We will use X" not "We should consider X".>

## Rationale

<Why was this option chosen over the alternatives? List the alternatives considered and why they were rejected.>

| Option | Pro | Con | Chosen? |
|--------|-----|-----|---------|
| <A>    | ... | ... | Yes |
| <B>    | ... | ... | No — reason |

## Consequences

### Positive
- <benefit 1>
- <benefit 2>

### Negative / Trade-offs
- <cost 1>
- <risk 1>

### Neutral
- <change in process or tooling that is neither good nor bad>

## References
- <link to relevant issue, PR, document, or external resource>
```

### 5. Link from index (if exists)
If `docs/adr/README.md` or `docs/adr/index.md` exists, append the new ADR to its table:

```markdown
| ADR | Title | Status | Date |
|-----|-------|--------|------|
| [ADR-NNNN](NNNN-title.md) | <title> | Accepted | YYYY-MM-DD |
```

If no index exists and this is the second or later ADR, create one.

### 6. Report
```
ADR created: docs/adr/<NNNN>-<title>.md
Status: <status>
Index updated: yes / no
```

## Guardrails
- An ADR records the decision as made — do not sanitize or omit the real trade-offs.
- Do not create an ADR for trivial choices (variable naming, minor config). Reserve for decisions that affect system structure, team workflow, or are hard to reverse.
- If the decision has already been partially implemented, note that in the **Context** section.
- If superseding an older ADR, update the older ADR's status to "Superseded by ADR-NNNN".
