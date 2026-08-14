---
name: handoff
description: Generate a structured session handoff document capturing progress, root causes, failed attempts, open issues, and next steps. Triggered by "generate handoff", "close session", "write handoff doc", "end of day", "EOD", "I'm done for today", "wrapping up", "switching tasks", "summarise what we did", "summarize progress", "session summary", "handoff".
---

# 📋 Handoff

## Purpose
Prevent context loss between agent or developer sessions. The handoff doc captures what happened, what was tried, what's unresolved, and what to do next — so the next session starts informed, not from scratch.

This is not a PR summary. It captures *debugging context*, *failed attempts*, and *open questions* that a diff cannot show.

## When to run
- End of a long debugging or implementation session
- Before handing work to another developer or agent
- When pausing a multi-day task
- After a commit completes successfully (see `rules/agent-behavior.mdc` § Session continuity) — a commit is a checkpoint worth protecting even if the session ends without a goodbye

## Steps

### 1. Gather session context
Run in parallel:
- `git log --oneline -10` — recent commits
- `git diff HEAD` — any uncommitted changes
- `git status` — working tree state

### 2. Review conversation history
Identify:
- What was the original goal?
- What was completed? (with file/line references where possible)
- What was attempted but failed? (include the reason it failed)
- What is still open or unresolved?
- What questions remain unanswered?

For every claim you're about to write down as "done" or "correct" — including your own — classify its evidence before writing it:

| Evidence level | What qualifies | Write it as |
|---|---|---|
| **Verified** | A test/build/lint actually ran and passed, or the user explicitly confirmed it ("yes that's right", "works now", approved the diff) | Stated as fact |
| **Committed, not confirmed** | The change was committed but nobody — human or test — actually checked the outcome is correct | Stated as fact, tagged `(committed, unreviewed)` |
| **Unverified claim** | You (the agent) asserted something was fixed/correct and the user simply moved on, changed topic, or didn't respond — no test, no explicit agreement | Listed separately under **Unverified claims**, never under "What was done" |

**The user not objecting is not the same as the user confirming.** If you proposed a fix and the conversation moved on without an explicit "yes" or a passing check, that fix is unverified — write it that way even if you privately believe it's correct.

### 3. Write the handoff document

Write to **two paths simultaneously**:

| Path | Purpose |
|------|---------|
| `.cursor/session-handoff.md` | Machine-readable — auto-injected at next session start |
| `HANDOFF.md` (repo root) | Human-readable — shareable, committable |

Both files get identical content. `.cursor/session-handoff.md` is read at the start of the next session per the **Session continuity** section of `rules/agent-behavior.mdc` — the agent checks for this file directly, so it starts warm without the developer having to do anything even though the `sessionStart` hook that was meant to do the same thing is currently broken upstream in Cursor (see `hooks/README.md`).

```markdown
# Handoff — <date>

## Goal
<One sentence: what this session set out to accomplish.>

## Status
<Completed / In Progress / Blocked>

## What was done
Only items with **Verified** or **Committed, not confirmed** evidence (see evidence table in SKILL.md). Nothing goes here on the strength of the agent's own belief alone.
- <bullet: file/feature changed and why> — `[verified: tests pass]` / `[verified: user confirmed]` / `[committed, unreviewed]`
- <cite files as `path/to/file.ts:line` where relevant>

## Unverified claims
Things asserted during the session (by the agent or otherwise) that were never independently confirmed — no test ran, no explicit user agreement. The next session should check these before building on them, not trust them.
- <claim> — <why it's unverified: e.g. "user changed topic before confirming"; "no test covers this path">

## What was attempted but did not work
| Approach | Why it failed |
|----------|--------------|
| <attempt> | <root cause or blocker> |

## Open issues
- [ ] <unresolved item — be specific>
- [ ] <open question that needs an answer>

## Recommended next steps
1. <concrete action with context>
2. <second action>

## Relevant files
- `<path>` — <one-line description of relevance>

## Skills that may help
- <skill-name> — <why relevant>
```

### 4. Reference, don't duplicate
- Link to existing files rather than pasting their content.
- Reference commit SHAs for specific changes rather than re-describing the diff.

### 5. Report
Tell the user: both files written, key open issues, and recommended first next step. Remind them that `.cursor/session-handoff.md` will be auto-loaded at the next session start.

## Output
- `.cursor/session-handoff.md` — auto-injected next session (do not commit this file; add to `.gitignore`)
- `HANDOFF.md` — shareable summary for the team or future self

## Gotchas
- If `.cursor/session-handoff.md` already exists from a prior session, overwrite it fully rather than appending — a stale entry left in place gets re-injected at every future session start, misleading the next session about current state.
- Don't write `.cursor/session-handoff.md` before checking `.gitignore` covers it — an uncommitted-but-untracked handoff file can end up accidentally staged in a broad `git add`.
- "What was attempted but failed" needs the actual reason it failed, not just that it did — a handoff that says "tried X, didn't work" without the root cause forces the next session to redo the diagnosis.
- The single biggest way a handoff misleads the next session: recording an agent's own claim as fact because the user didn't push back on it. A user going quiet or changing the subject is not confirmation — it can just as easily mean they didn't notice, didn't understand, or silently disagreed and moved on. Anything without a test result or an explicit "yes" belongs under **Unverified claims**, not **What was done** — see the evidence table in Step 2.
- Resist the pull to upgrade an item's evidence level to make the handoff look more finished. "Committed, not confirmed" and "Verified" read very differently to the next session — don't blur them because the diff looks plausible.
