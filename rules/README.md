<div align="center">

# 🛡️ Rules

[![rules](https://img.shields.io/badge/rules-8%20total-6366f1?style=flat-square)](#rule-reference)
[![always-on](https://img.shields.io/badge/always--on-3-a855f7?style=flat-square)](#rule-reference)
[![conditional](https://img.shields.io/badge/conditional-5-06b6d4?style=flat-square)](#rule-reference)

Agent guardrails loaded automatically every session. Three rules apply to all files; five apply conditionally, either by file type or by task (e.g. git operations).
No trigger phrase needed. No configuration required.

</div>

---

## How rules work

Rules are `.mdc` files with a YAML frontmatter block that tells Cursor when to apply them:

```yaml
---
description: What this rule does
alwaysApply: true       # fires on every file
globs: **/*.md,**/*.mdc # or: fires only on matching files
---
```

- `alwaysApply: true` — rule is injected into every agent context window
- `globs` without `alwaysApply` — rule fires only when the active file matches the pattern
- Both can coexist: `alwaysApply: true` + `globs` scopes the rule to matching files only

Rules live in two places after install:

| Location | Installed by | Visible in Settings UI? |
|----------|-------------|------------------------|
| `~/.cursor/rules/` | `install.sh` / `install.ps1` | ❌ No — active but not listed |
| `<repo>/.cursor/rules/` | `sync-project.sh` / `sync-project.ps1` | ✅ Yes — Settings → Rules, Commands |

---

## Rule reference

**Always-on**

| File | `alwaysApply` | Scope | Enforces |
|------|:-------------:|-------|---------|
| `core-development.mdc` | ✅ | all files | Minimal diffs · match existing style · no placeholders · no over-engineering |
| `agent-behavior.mdc` | ✅ | all files | Read before edit · use tools not shell · concise output · no preamble · parallel tool calls · never test scripts against real `$HOME`/global state |
| `security-basics.mdc` | ✅ | all files | No secrets in code or commits · warn before staging sensitive files |

**Conditional (file-type or task scoped)**

| File | `alwaysApply` | Scope | Enforces |
|------|:-------------:|-------|---------|
| `git-safety.mdc` | ❌ | git operations (description-triggered) | No force-push main · no `--no-verify` · commit only when asked · bash HEREDOC or PowerShell here-string message format · branch names match the repo's existing convention |
| `documentation.mdc` | ❌ | `**/*.md`, `**/*.mdc` | Precise prose · no invented requirements · cite existing content · no duplicate files |
| `transaction-atomicity.mdc` | ❌ | `*.ts/.js/.py/.go/.rb/.java/.cs` | Multi-step DB writes must use explicit transaction wrappers with rollback paths |
| `architectural-drift.mdc` | ❌ | `*.ts/.js/.py/.go/.java/.rb/.cs` | No cross-domain imports into private paths; defers to `.deprc.json` if present |
| `telemetry-standards.mdc` | ❌ | `*.ts/.js/.py/.go/.java/.rb/.cs` | Suggests structured logging metadata fields — only when the project already has a structured logger configured; silent otherwise |

---

## Adding a project-specific rule

After `bootstrap-project.sh`, your repo gets `.cursor/rules/project-context.mdc` — edit that file for project-level overrides. You do not need to add a new file.

If you genuinely need a separate project rule (e.g. a client-requirements pointer):

1. Create `.cursor/rules/<name>.mdc` in the repo
2. Add frontmatter with `description` and `alwaysApply: true` (or a `globs` pattern)
3. Keep it focused — one rule, one concern
4. Commit it — teammates get it on `git pull`

Rules in `<repo>/.cursor/rules/` stack with team rules. They do not override them.

---

## Changing a team rule

Team rules are maintainer-only. See [CONTRIBUTING.md](../CONTRIBUTING.md) for the process.

> Every `alwaysApply: true` rule adds token cost to **every session for every user**. Rules are kept intentionally minimal — each one was retained because it measurably changes agent behaviour.
