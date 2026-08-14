<div align="center">

# 📋 Changelog

[![Version](https://img.shields.io/badge/latest-1.8.0-6366f1?style=flat-square)](https://github.com/SID-SURANGE/cursor-team-ops/releases)

All notable changes to cursor-team-ops are documented here.
Versions follow [Semantic Versioning](https://semver.org/).

</div>

---

## 1.8.0 — 2026-08-14

Positioning and accuracy pass, prompted by a factual competitive review against the Cursor/Claude rules-and-skills ecosystem (see repo discussion). Two findings drove this release: this repo's most direct competitor is Cursor's own official first-party `cursor-team-kit` plugin (free, zero-friction install, 3 skill names in common), and this repo's one genuinely unduplicated asset — `git-guardrails`' hook-based `deny`/`ask` enforcement — wasn't being led with clearly enough.

### Fixed

- **`README.md`, `plugins/git-guardrails/README.md` — corrected a false installation claim.** Both said "search the Marketplace browser and install" was available to any individual user. Verified against Cursor's own plugin docs: "Import from Repo" is a Teams/Enterprise-admin-only feature, and this plugin has not been submitted to Cursor's public marketplace, so it does not appear in a Marketplace browser search for anyone. Docs now state this plainly and point individual users to the script install (`install.sh`/`install.ps1`), which is the actual working path.

### Changed

- **`install.sh` / `install.ps1` / `sync-project.sh` / `sync-project.ps1` — default (`standard`) profile no longer installs the requirements/consulting skill cluster** (`requirements-qa`, `requirements-synthesis`, `spec-driven-development`, `architecture-decision-records`). These serve BRD-heavy/client-facing workflows, not day-to-day engineering hygiene, and were diluting the kit's "niche, daily-useful" positioning by being bundled in by default. Opt in with `--profile=full` (`-InstallProfile full` / `-SyncProfile full` on Windows) or an explicit `--skills=`/`-Skills` allowlist. This is a default-behavior change — teams relying on `standard` installing everything should re-run with `--profile=full` to keep the prior behavior.
- `sync-project.ps1` — brought up to parity with `sync-project.sh`: previously had no `-SyncProfile`/`-Rules`/`-Skills` support at all and always synced every rule and skill unconditionally.
- `README.md` — corrected stale version badge (1.4.0 → 1.8.0), stale skill count (said 20, actual 21), and hooks table accuracy: `db-migration-guard.sh` and `license-gatekeeper.sh` were documented as "Blocks" but were downgraded to "Asks" back in 1.6.0 — the docs never caught up until now. Added the previously-missing `onboarding` skill to the core skills table.
- `ONBOARDING.md`, `plugins/git-guardrails/README.md` — stale version badges corrected. `plugin.json` / `marketplace.json` version fields bumped to match.

### Added

- `README.md` — new "How this compares" section addressing the two real overlaps head-on: Cursor's own official `cursor-team-kit` plugin (shares 3 skill names with this repo: `pr-review-canvas`, `deslop`, `workflow-from-chats`) and Cursor Bugbot (automated PR review). States plainly what this repo does that neither does — hook-based `deny`/`ask` enforcement that runs as policy, not advice.
- `skills/core/pr-review-canvas`, `skills/core/deslop`, `skills/community/workflow-from-chats` — each now has a "Note:" line under Purpose stating the name overlaps with Cursor's official plugin and how this repo's version differs, so a side-by-side comparison doesn't read as a copy.
- `skills/community/workflow-from-chats` — the `SKILL.md` template it generates now includes a required `## Gotchas` section (previously missing, inconsistent with this kit's own `CONTRIBUTING.md` requirement as of 1.7.0).
- `CONTRIBUTING.md` — the skill quality bar now asks contributors to check proposed skill names against Cursor's official `cursor-team-kit` plugin too, not just this repo's own skills.

---

## 1.7.0 — 2026-08-14

### Added

- Every `SKILL.md` (21 core + community skills) — a `## Gotchas` section documenting real failure modes in that skill's own steps (a git command that errors on an edge case, a heuristic that's wrong for some inputs), distinct from preventive Guardrails
- `CONTRIBUTING.md` — Gotchas is now a required SKILL.md section for new skill contributions; explicit 500-line size ceiling documented for both rules and skills (was previously unstated policy)
- `rules/agent-behavior.mdc` — "Session continuity" section: checks for `.cursor/session-handoff.md` directly at session start (independent of the `sessionStart` hook), and proactively offers to write/refresh a handoff at natural stopping points and after a successful commit
- `skills/core/handoff/SKILL.md` — evidence tagging for handoff content: "What was done" items now require `verified` / `committed, unreviewed` tags, and a new "Unverified claims" section captures agent assertions the user never explicitly confirmed, so silence isn't mistaken for agreement in the next session

### Fixed

- `hooks/session-context.sh` reliance — `sessionStart` hooks' `additional_context` field is confirmed broken upstream in Cursor (acknowledged by Cursor staff, unresolved as of August 2026: hook output never reaches the agent). Session handoff now works around this via a rule-based check instead of depending solely on the hook; `hooks/README.md` documents the known bug

---

## 1.6.0 — 2026-08-13

### Added

- `install.sh` / `install.ps1` / `sync-project.sh` — `--profile=minimal|standard|full` flag (plus `--rules=`/`--skills=` explicit allowlists), so teams can opt out of installing every rule and skill by default instead of always getting the full bundle
- `rules/agent-behavior.mdc` — "Environment safety" section: never test scripts against real `$HOME`/`~/.cursor`/global config, verify env-var propagation across spawned shells explicitly
- PowerShell equivalents alongside every bash/POSIX command example across `rules/git-safety.mdc` and 11 `SKILL.md` files (`env-drift-check`, `release-readiness`, `commit-history-audit`, `onboarding`, `architecture-decision-records`, `pre-commit-check`, `pr-summary`, `sync-docs-after-edit`, `write-changelog`, `requirements-synthesis`) — a no-assumptions audit found these assumed a POSIX/bash shell and would fail outright on native Windows PowerShell 5.1

### Changed

- `rules/git-safety.mdc` — dropped `alwaysApply: true` (was paying its token cost on every session regardless of relevance); branch naming now detects and matches the repo's existing convention instead of imposing a fixed pattern
- `rules/telemetry-standards.mdc` — softened from "must"/"reject" to advisory, and now skips entirely when the project has no structured logger already configured, instead of nagging on plain `console.log`/`print` (the norm for most projects)
- `rules/transaction-atomicity.mdc` — trimmed redundant duplicate-language code samples
- `skills/core/release-readiness`, `skills/core/env-drift-check`, `skills/community/ci-cd-pipeline`, `skills/community/requirements-synthesis` — marked `disable-model-invocation: true` (largest + rarest-used skills; now explicit-invoke only instead of auto-scanned every session)
- `hooks/session-context.sh` — no longer injects a hardcoded inventory of every installed skill/rule into every session; `session-handoff.md` inclusion capped at 100 lines instead of unbounded
- `hooks/db-migration-guard.sh`, `hooks/license-gatekeeper.sh` — downgraded from `deny` to `ask`; their concerns (production-scale locking, commercial license compliance) don't apply to every repo, so the developer confirms instead of being hard-blocked
- `plugins/git-guardrails/` — hook/rule copies re-synced with the changes above; README and manifest descriptions updated to reflect the ask-vs-deny split instead of describing all three hooks as hard blocks

### Fixed

- `install.ps1` — a 3-argument `Join-Path` call is unsupported on Windows PowerShell 5.1 (only PS 6+); rule/skill/hook installation was silently broken on native Windows PowerShell until this fix
- `skills/community/requirements-synthesis` — unquoted `pip install markitdown[all]` breaks under macOS's default zsh shell (glob expansion); now quoted
- Corrected `.team-kit-version` → `.team-ops-version` references in `CLAUDE.md`, `ONBOARDING.md`, `README.md`, and the bug-report issue template — the actual filename `install.sh`/`session-context.sh` use, which didn't match the docs
- `hooks/README.md`, `rules/README.md`, `skills/core/README.md`, `skills/community/README.md` — corrected stale rule/skill counts and behavior descriptions (deny→ask, `alwaysApply` status, missing `onboarding` skill entry) to match current code

---

## 1.5.0 — 2026-07-12

### Added

- `plugins/git-guardrails/` — first Cursor **marketplace plugin**: bundles the three blocking `beforeShellExecution` hooks (`git-guard`, `db-migration-guard`, `license-gatekeeper`) plus the `git-safety` rule, installable via the plugin marketplace / Team Marketplace "Import from Repo"
- `.cursor-plugin/marketplace.json` — repo-as-marketplace catalog (`pluginRoot: plugins`)
- `plugins/git-guardrails/.cursor-plugin/plugin.json` + `hooks/hooks.json` — plugin manifest and hook registration
- `plugins/git-guardrails/logo.{svg,png}` — square 1:1 marketplace logo (shield + git-branch), shown in the plugin README and used for the publisher listing
- Badges (Cursor Plugin / version / license) on the git-guardrails README
- CI: `plugins/**/README.md` added to the markdown-lint glob

### Changed

- `README.md` — plugin marketplace install is now the primary path; script install (`install.sh` / `sync-project.sh`) demoted to a documented alternative for teams without plugin support
- Artefacts are copied into the plugin tree (additive); the flat `rules/`/`skills/`/`hooks/` layout and its installer scripts are unchanged and still supported

---

## 1.4.0 — 2026-06-13

### Added

- `skills/core/handoff` — structured session-close document capturing progress, failed attempts, open issues, and next steps; triggered by "generate handoff" / "close session"
- `hooks/db-migration-guard.sh` — pre-commit hook blocking destructive migration patterns: DROP COLUMN, NOT NULL without DEFAULT, non-CONCURRENT index creation, DROP TABLE, TRUNCATE
- `hooks/license-gatekeeper.sh` — pre-commit hook blocking packages with copyleft licenses (GPL-2/3, AGPL-3, LGPL, SSPL, EUPL) on lockfile changes; uses license-checker / pip-licenses / cargo-license where available
- `rules/transaction-atomicity.mdc` — conditional rule flagging multi-step DB writes missing explicit transaction wrappers; scoped to `.ts/.js/.py/.go/.rb/.java/.cs`
- `rules/architectural-drift.mdc` — conditional rule flagging cross-domain imports into private paths; defers to `.deprc.json` if present
- `rules/telemetry-standards.mdc` — conditional rule rejecting plain-string log calls and requiring structured objects with `requestId`/`traceId`/`message`
- `templates/commands/handoff.md` — `/handoff` slash command template scaffolded into new repos
- `skills/community/requirements-synthesis` — ingest multiple client documents (PDF, DOCX, XLSX, HTML, images, text) and synthesize into a single `REQUIREMENTS-DRAFT.md`; requires `pip install markitdown[all]`

### Changed

- `hooks.json` — registered `db-migration-guard.sh` and `license-gatekeeper.sh` on `git commit` trigger
- `hooks/session-context.sh` — updated skills, rules, and hooks inventory; removed stale deleted skill references
- `.markdownlint.json` — disabled MD060 (table column style) introduced by markdownlint-cli2 v0.22.1
- `README.md`, `rules/README.md`, `skills/core/README.md`, `hooks/README.md`, `ONBOARDING.md` — updated counts, tables, and references to reflect all additions

### Removed

- Stale skill references (`discover-repo`, `verify-this`, `fix-merge-conflicts`, `systematic-debugging`, `writing-tests`) removed from `session-context.sh` and all documentation (skills themselves were removed in a prior session)

---

## 1.3.0 — 2026-05-26

### Added

- `skills/community/spec-driven-development` — write a spec before touching code; gated workflow (Specify → Plan → Implement)
- `skills/community/security-hardening` — OWASP Top 10 coverage, boundary system, pre-deployment security checklist
- `skills/community/ci-cd-pipeline` — quality gate pipeline setup, GitHub Actions config, deployment strategy, CI failure feedback loop
- `skills/community/ATTRIBUTIONS.md` — legal attribution record for community skills informed by external MIT-licensed work

### Changed

- `README.md` — added community skills table with trigger phrases and attribution link
- `session-context.sh` — updated skills list to include 3 new community skills

---

## 1.2.0 — 2026-05-26

### Added

- `hooks/README.md` — full schema reference for hooks.json, supported events, response format, testing guide, project-level hooks
- `TEAMS.md` — real-world team setup examples for web app, API, and monorepo teams
- `CONTRIBUTING.md` — documented `disable-model-invocation` frontmatter flag with guidance on when to set it

### Changed

- `README.md` — rewritten with team-ops positioning, skills-vs-commands distinction, rolling out to a team section
- `install.sh` — fixed operator precedence bug on symlink removal (`||` + `&&` without braces); added VERSION file existence check
- `sync-project.sh` — fixed hardcoded project name "briefcast" in output; added existence check on repo path argument
- `hooks/git-guard.sh` — added early exit for empty command string to prevent grep exit-code misfires

### Fixed

- `install.ps1` — added missing trailing newline to prevent prompt appearing on last output line

---

## 1.1.1 — 2026-05-26

### Added

- `sync-project.sh` / `sync-project.ps1` — copy team rules and skills into `<repo>/.cursor/` so they appear in Cursor Settings

### Changed

- `README.md` — document machine vs project install, Settings UI behavior, Windows Git Bash note
- `ONBOARDING.md` — fix verify checklist (filesystem vs Settings); troubleshooting for empty Rules/Skills panel

---

## 1.1.0 — 2026-05-12

### Added

- `agent-behavior.mdc` — Token economy section (concise responses, no preamble, tables over prose)
- `workflow-from-chats` skill — extract a repeated conversation pattern into a ready-to-commit SKILL.md
- `verify-this` skill — structured evidence chain: baseline → treatment → evidence → verdict
- `pr-review-canvas` skill — group PR changes by purpose, flag risky sections, produce reviewer map
- `deslop` skill — strip narrating comments, dead imports/variables, and empty try/catches
- `fix-merge-conflicts` skill — resolve conflict markers with explanation and post-resolution verification
- `sync-docs-after-edit` skill — scan all .md files after local changes and flag stale documentation
- `systematic-debugging` skill — hypothesis → reproduction → experiment → evidence → verdict loop
- `writing-tests` skill — test structure for any language: happy path, edge cases, error paths
- `architecture-decision-records` skill — create or update ADR files following the standard template

---

## 1.0.0 — 2026-04-28

Initial release.

### Added

- `core-development.mdc` — minimal diff, style, tests, comments
- `git-safety.mdc` — commit discipline, destructive command guards
- `agent-behavior.mdc` — read-before-edit, persistence, communication
- `security-basics.mdc` — no secrets in code/commits
- `documentation.mdc` — doc tone and BRD/requirements standards
- `discover-repo` skill — rapid codebase orientation
- `pre-commit-check` skill — staged diff review before commit
- `pr-summary` skill — PR title, summary, test plan via gh CLI
- `minimal-diff-review` skill — scope creep and convention drift check
- `requirements-qa` skill — BRD/discovery doc quality check
- `git-guard.sh` hook — blocks/warns on destructive git commands
- `session-context.sh` hook — injects kit version at session start
- `install.sh` — symlinks kit into `~/.cursor/`
- `bootstrap-project.sh` — scaffolds `.cursor/` + `AGENTS.md` in any repo
- `templates/AGENTS.md` and `templates/project-context.mdc`
