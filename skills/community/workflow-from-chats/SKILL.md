---
name: workflow-from-chats
description: Scan the recent conversation for a repeated prompt pattern and produce a ready-to-commit SKILL.md. Triggered by "make this a skill", "extract this workflow", "save this as a skill".
disable-model-invocation: true
---

# ⚡ Skill: workflow-from-chats

## Purpose
Turn a repeated or valuable conversation pattern into a reusable, committable `SKILL.md` so the team never has to re-explain the same workflow.

Note: Cursor's own official `cursor-team-kit` plugin ships a skill with this same name. This version follows this repo's own `CONTRIBUTING.md` `SKILL.md` template (including the required Gotchas section — see Step 3), so a skill extracted here already matches the format the rest of this kit expects.

## Steps

### 1. Identify the pattern
- Review the recent conversation (or the user-selected excerpt).
- Look for:
  - A multi-step workflow the user walked the agent through manually.
  - A prompt the user re-typed with minor variations.
  - A sequence of tool calls that produced a consistently useful outcome.
- If ambiguous, ask: "Which part of this conversation should become the skill?"

### 2. Name and classify
- Choose a short kebab-case name (e.g. `fix-slow-query`, `generate-migration`).
- Pick a trigger phrase that would naturally recall this skill in future sessions.
- Identify the skill's scope: does it belong in the team kit (`~/.cursor/skills/`) or the current project (`.cursor/skills/`)?

### 3. Draft the SKILL.md
Produce a file with this structure:

```markdown
---
name: <kebab-case-name>
description: <One sentence. Include the trigger phrases.>
---

# Skill: <name>

## Purpose
<Why this skill exists — the pain it avoids.>

## Trigger phrases
- "<phrase 1>"
- "<phrase 2>"

## Steps
<Numbered steps extracted from the conversation. Be prescriptive, not descriptive.>

## Output
<What the skill produces — files created, commands run, verdicts returned.>

## Example
<Optional: a minimal before/after or sample invocation.>

## Gotchas
<At least one real failure mode from the source conversation — a command that errored on
an edge case, an assumption that turned out wrong, a step that needed retrying. If the
conversation only ran cleanly once, say the steps are unverified beyond that one run
rather than inventing a Gotcha that wasn't actually observed.>
```

### 4. Validate before writing
- Confirm the steps are reproducible without the original conversation context.
- Remove any project-specific details if the skill targets `~/.cursor/skills/`.
- Ensure trigger phrases are distinct from existing skills.
- Confirm the Gotchas section reflects something that actually happened in the conversation, not a generic filler bullet.

### 5. Write and report
- Write the file to the correct location.
- Report: skill name, file path, trigger phrases, and one-line description.

## Output
A single `SKILL.md` ready to commit.

## Gotchas
- A skill drafted right after one successful run tends to encode incidental details of that specific run — a hardcoded filename, a one-off branch name, a value that happened to be correct that time — as if they were general steps. Re-read the draft looking specifically for anything that only makes sense given this session's exact context, and generalize or remove it.
- If the source conversation only ran the workflow once, the "steps" are a hypothesis about the general case, not a verified procedure — say so, and suggest the user try the extracted skill once before relying on it.
