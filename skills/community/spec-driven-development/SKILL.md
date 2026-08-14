---
name: spec-driven-development
description: Write a structured specification before touching any code. Use when starting a new feature, facing ambiguous requirements, or when the change touches more than one file. Triggered by "write a spec", "spec this out", "spec-driven", "what should I build", "define this first".
attribution: >
  Independently written. The spec-before-code methodology is a well-established
  engineering practice. The workflow structure in this skill was informed by patterns
  in agent-skills (github.com/addyosmani/agent-skills, © Addy Osmani, MIT License).
  No text was copied; this file is an original work.
---

# 📐 Skill: spec-driven-development

## Purpose

Prevent wasted implementation work by making the shared understanding explicit before any code is written. A spec surfaces assumptions, resolves ambiguity, and gives both the developer and the agent a stable reference point throughout the work. Retrofitting clarity after implementation costs 5–10× more than establishing it upfront.

## Trigger phrases

- "write a spec for this"
- "spec this out"
- "spec-driven"
- "define this before we build"
- "what should I build"
- "I need a spec"

## When to use

| Use spec-driven | Skip (proceed directly) |
|----------------|------------------------|
| New feature or module | Single-line typo fix |
| Ambiguous or verbal requirements | Self-evident single-file change |
| Change touches more than one file | Direct user instruction with no ambiguity |
| Estimated work > 30 minutes | Reversible experiment / spike |
| Multiple engineers will be involved | |

---

## Steps

### 1. Surface assumptions before writing anything

Before drafting the spec, explicitly list what you are assuming:

```
Assumptions I'm making:
- [ ] The user wants X, not Y
- [ ] This will use the existing auth system
- [ ] No DB schema changes are needed
```

Ask the user to confirm or correct before continuing.

### 2. Write the spec

A complete spec has six sections:

```markdown
## Objective
What this change achieves. State it as a testable success criterion:
"A user can reset their password via email. The flow completes in under 3 steps."

## Commands
Build, test, and run commands for this project:
- Install: `npm install`
- Dev: `npm run dev`
- Test: `npm test`
- Lint: `npm run lint`

## Scope
Files and modules this change will touch.
Files and modules this change must NOT touch.

## Design
How it will be built — data flow, key functions, API shape, schema changes.
Keep it concrete: name the functions, files, and interfaces.

## Testing strategy
- Unit tests: what and where
- Integration tests: which flows
- Manual verification steps

## Boundaries
| Always do | Ask first | Never do |
|-----------|-----------|----------|
| ... | ... | ... |
```

### 3. Gate: human review before implementation

Present the spec and **stop**. Do not start coding until the user explicitly approves it or requests changes.

If the spec reveals the requirements are unclear, surface that as an open question — do not resolve ambiguity silently.

### 4. Implement against the spec

- Reference the spec as you work. If the implementation diverges from the spec, flag it and update the spec first.
- Keep the spec as a living document — update it when scope changes, not after.

### 5. Reference the spec in your PR

In the PR description, link or quote the relevant spec sections. Reviewers should be able to map every diff line back to a spec requirement.

---

## Output

A markdown spec block covering all six sections above, ready to be saved as `docs/specs/<feature-name>.md` or pasted into a GitHub issue.

## Guardrails

- Never start implementation without spec approval when the scope qualifies.
- Never resolve ambiguous requirements by guessing — surface them as questions.
- Never let the spec become out of date — update it before changing course, not after.
- A spec is not a design document for its own sake. If it can't be implemented, it's not done.

## Gotchas
- The "stop and wait for approval" gate assumes a human is present to approve. In a non-interactive or autonomous run with nobody to ask, say explicitly that approval couldn't be obtained rather than treating silence as approval and proceeding.
- A spec that goes stale mid-implementation is worse than no spec — if the diff has visibly diverged from what's written, stop and reconcile the spec before writing more code, not at the end.
