<div align="center">

# 🌱 Community Skills

[![Contribute](https://img.shields.io/badge/contribute-a%20skill-a855f7?style=flat-square)](../../CONTRIBUTING.md)
[![Attribution](https://img.shields.io/badge/attributions-on%20file-6366f1?style=flat-square)](ATTRIBUTIONS.md)

Community-contributed skills — reviewed, attributed, and ready to use.
Not yet in core, but tested on real projects.

</div>

---

## Skills

| Skill | Triggered by | Auto-scanned? | External deps? |
|-------|-------------|:--------------:|---------------|
| `workflow-from-chats` | *"make this a skill"* / *"extract this workflow"* | ❌ explicit only | None |
| `spec-driven-development` | *"write a spec"* / *"spec this out"* | ✅ | None |
| `security-hardening` | *"security review"* / *"harden this"* | ✅ | None |
| `ci-cd-pipeline` | *"set up CI"* / *"add GitHub Actions"* | ❌ explicit only | None |
| `requirements-synthesis` | *"synthesize these requirements"* / *"read these client docs"* | ❌ explicit only | `pip install "markitdown[all]"` |

---

## Quality bar for community skills

- Generic — works for any language, framework, or project type
- Self-contained — no external dependencies beyond common shell tools (exception: skills that require a clearly documented one-time install are allowed)
- Distinct trigger phrases — doesn't overlap with an existing skill
- Tested by the contributor on at least one real project

## How to contribute a skill

See [CONTRIBUTING.md](../../CONTRIBUTING.md).

## Promoting to core

A community skill may be promoted to `skills/core/` after:

- 3+ months in `skills/community/` with no reported issues
- Positive feedback from multiple teams
- Review and approval by a maintainer
