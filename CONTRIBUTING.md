<div align="center">

# 🤝 Contributing to cursor-team-ops

[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-3fb950?style=flat-square)](https://github.com/SID-SURANGE/cursor-team-ops/pulls)
[![License](https://img.shields.io/badge/license-MIT-a855f7?style=flat-square)](LICENSE)

**This kit is used by real teams in production.**
The bar is intentional — but not high. Start with a community skill.

</div>

---

---

## What belongs where

| Layer | Who can contribute | Bar |
|-------|--------------------|-----|
| `skills/community/` | Anyone | Open — see skill quality bar below |
| `skills/core/` | Maintainers only | Promoted from community after proven track record |
| `rules/` | Maintainers only | Conservative — every always-apply rule adds token cost for everyone |
| `hooks/` | Maintainers only | Shell execution — requires careful review |
| `install.sh` / `install.ps1` | Maintainers only | Runs on contributor machines — high trust required |
| `sync-project.sh` / `sync-project.ps1` | Maintainers only | Copies rules/skills into a repo's `.cursor/` |

**Start with a skill in `skills/community/`.** That is the correct entry point for almost all contributions.

---

## Quality bar for a community skill

A skill PR will be merged if it satisfies all of the following:

- [ ] **Generic** — works for any language, framework, and project type without modification
- [ ] **Self-contained** — relies only on common tools (git, gh, bash, standard language CLIs). No pip install, no npm global install
- [ ] **Distinct** — trigger phrases do not overlap with an existing skill. Check `skills/core/*/SKILL.md` and `skills/community/*/SKILL.md`. Also check the name against Cursor's own official `cursor-team-kit` plugin (`/add-plugin cursor-team-kit` in Cursor) — if it ships a skill with the same name, add a short "Note:" line under Purpose explaining how this repo's version differs (see `skills/core/deslop/SKILL.md` for the pattern), so a side-by-side comparison doesn't read as a copy
- [ ] **Tested** — you have run the skill on at least one real project and it produced a useful result
- [ ] **Original** — you wrote the SKILL.md yourself. If inspired by another source, credit it in the file header
- [ ] **Rights confirmed** — see the sign-off section below
- [ ] **Under 500 lines** — see Size policy below
- [ ] **Has a Gotchas section** — real failure modes, not restated Guardrails. See below

---

## SKILL.md format

Every skill must follow this structure:

```markdown
---
name: <kebab-case-name>
description: <One sentence. Include trigger phrases, or use when_to_use — see note below.>
disable-model-invocation: true   # optional — see note below
---

# Skill: <name>

## Purpose
<Why this skill exists — the pain it prevents.>

## Trigger phrases
- "<phrase 1>"
- "<phrase 2>"

## Steps
<Numbered, prescriptive steps.>

## Output
<What the skill produces.>

## Guardrails  ← optional but encouraged
<What the skill should never do, decided up front — preventive rules.>

## Gotchas  ← required
<Real failure modes this skill's actual steps can hit — a command that errors on
an edge case, a heuristic that's wrong for some inputs, a check that silently
does nothing if a precondition isn't met. Not a restatement of Guardrails: a
Guardrail says "never do X"; a Gotcha says "here's how step N breaks and what
to do about it." If you haven't hit a real failure yet, think through the
edge cases of your own Steps section instead of leaving this generic.>
```

**Rules for the description field:** The agent uses this to decide when to load the skill. Make it specific enough that it fires on the right trigger and not on unrelated tasks. You can either bake trigger phrases into the `description` sentence (what every skill in this kit does today) or split them into a separate `when_to_use` frontmatter field — both are valid; `description` + `when_to_use` combined are capped at 1,536 characters by Claude Code.

**`disable-model-invocation: true`** — Add this flag when your skill is a pure procedure (a checklist the agent executes directly) and should never itself call out to another model or sub-agent. Most core skills set this. Omit it when your skill involves open-ended reasoning or delegation. If unsure, omit it.

**Gotchas vs. Guardrails:** Guardrails are decided before anything goes wrong ("never remove the only comment explaining a non-obvious rule"). Gotchas are learned from how the skill's own steps actually fail ("`git describe --tags --abbrev=0` exits non-zero when there are no tags — the fallback path must run, not error out"). A skill can have one, the other, or both, but a skill with concrete Steps almost always has a real Gotcha if you trace through what happens when a command's assumption doesn't hold. Update this section over time as new failure modes surface in real use — it is the single highest-value section for a skill that's actually been run.

### Size policy

Keep `SKILL.md` under **500 lines** (same ceiling as rules — see `rules/README.md`). If a skill is approaching that, push detail into supporting files in its directory (`references/`, `scripts/`, `assets/`) and link to them from `SKILL.md` rather than inlining everything — Claude and Cursor load those files only when needed, so this keeps the always-loaded description cheap while the skill stays fully capable. No skill in this kit currently needs this; it's here so growth doesn't silently blow past the ceiling.

---

## How to submit

1. **Open an issue first** using the [New Skill Proposal](.github/ISSUE_TEMPLATE/new-skill.yml) template. Describe the use case in 2–3 sentences. This avoids duplicate work.
2. Fork the repo and create a branch: `skill/<your-skill-name>`
3. Add your skill directory: `skills/community/<your-skill-name>/SKILL.md`
4. Test it: `bash install.sh`, then `bash sync-project.sh /path/to/test-repo`, open Cursor, trigger your skill, and verify it works as described
5. Open a PR against `main`. Fill in the PR template.

---

## What not to contribute (and why)

| Rejected type | Reason |
|---------------|--------|
| Framework-specific skills (`react-patterns`, `django-setup`) | Too narrow — better in a project-level `.cursor/skills/` |
| Skills that duplicate existing ones | See `skills/core/` list in README |
| New always-apply rules | Each one adds token overhead for every user. File a discussion instead |
| Changes to `install.sh` / `install.ps1` | These run on machines — maintainer-only |
| Skills requiring external service accounts | Not self-contained |

---

## Sign-off (required)

By submitting a PR, you confirm:

> I wrote this contribution myself (or have the rights to submit it), it does not reproduce copyrighted text from another source without permission, and I agree to release it under the MIT License that governs this repository.

Add this line to your PR description:

```text
Signed-off-by: Your Name <your@email.com>
```

---

## Promoting a community skill to core

Community skills may be nominated for promotion to `skills/core/` after:

- 3+ months in `skills/community/` with no open bugs
- Reported as useful by at least two independent teams
- Clean, minimal SKILL.md (no framework-specific branches, no external dependencies)

Open a discussion to nominate. Maintainers make the final call.

---

## Questions

Open a [GitHub Discussion](../../discussions) rather than an issue for general questions about the kit's design or direction.
