<div align="center">

<img src="assets/banner.png" alt="cursor-team-ops — enforcement & release-hygiene layer for Cursor agents" width="100%" />

# ⚙️ cursor-team-ops

**Hard guardrails and release discipline for Cursor agents**

Blocking hooks, commit hygiene, and docs-ops that advisory rules can't enforce — for your whole team.

[![Version](https://img.shields.io/badge/version-1.8.0-6366f1?style=flat-square)](CHANGELOG.md)
[![License](https://img.shields.io/badge/license-MIT-a855f7?style=flat-square)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-06b6d4?style=flat-square)](#install-once-per-machine)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-3fb950?style=flat-square)](CONTRIBUTING.md)
[![Code of Conduct](https://img.shields.io/badge/code%20of%20conduct-v2.1-06b6d4?style=flat-square)](CODE_OF_CONDUCT.md)
[![Security Policy](https://img.shields.io/badge/security-policy-e85d4a?style=flat-square)](SECURITY.md)

</div>

---

## Why this exists

Most Cursor setups are solo configurations — copied rules, hand-pasted skills, no enforcement. cursor-team-ops solves the team problem:

```text
git clone cursor-team-ops          →   bash install.sh          →   bash sync-project.sh
     ↓                                      ↓                              ↓
 get the kit                      rules + skills on             same setup in every
 on your machine                  your machine                  repo your team uses
```

One `git pull` on the kit keeps every developer and every repo in sync.

---

## What's included

| Layer | What it does |
|-------|-------------|
| 🛡️ **8 rules** | 5 always-on guardrails + 3 conditional rules (DB transactions, import boundaries, structured logging) |
| 🧠 **21 skills** | 17 installed by default (`standard` profile) — PR review, commit hygiene, docs sync, session handoffs. 4 more (requirements/ADR/spec workflow) are opt-in via `--profile=full` — see [Choosing what gets installed](#install-via-scripts-alternative) |
| 🪝 **4 hooks** | `git-guard.sh` (blocks) · `db-migration-guard.sh` (asks) · `license-gatekeeper.sh` (asks) · `session-context.sh` |
| ⚡ **4 commands** | `/pr` · `/review` · `/fix-issue` · `/handoff` — starter slash commands for every repo |
| 📋 **Templates** | `AGENTS.md` + `project-context.mdc` scaffolded into every new repo |

---

## How this compares

Two honest comparisons worth making before you install this instead of something else:

**vs. Cursor's own official `cursor-team-kit` plugin** (`/add-plugin cursor-team-kit`) — Cursor ships an 18-skill first-party plugin covering CI/PR workflow (`fix-ci`, `loop-on-ci`, `get-pr-comments`, `weekly-review`) and two of its skill *names* overlap with this repo's (`deslop`, `workflow-from-chats`, `pr-review-canvas`). If you only want CI-loop and PR-summary automation, the official plugin is free, zero-install, and well-maintained — use it. What it does **not** ship is enforcement: its 2 rules are TypeScript style rules (`typescript-exhaustive-switch`, `no-inline-imports`), not policy. Nothing in Cursor's own plugin can stop an agent from force-pushing `main` or committing a `DROP TABLE` migration — a rule is advice the agent can still ignore. `git-guardrails` in this repo runs as a `beforeShellExecution` hook that can `deny` or `ask` *before* the command executes. That's the part worth installing this repo for, whether or not you also use Cursor's own kit alongside it.

**vs. Cursor Bugbot** — Bugbot automatically reviews every pushed PR on GitHub. `minimal-diff-review` and `pr-review-canvas` here are on-demand, local-diff, pre-PR chat tools — useful *before* you push, not a replacement for an automated PR gate. If your team already runs Bugbot, treat these two skills as a pre-flight check, not a duplicate reviewer.

**The one thing not duplicated anywhere:** hook-based `deny`/`ask` enforcement (`plugins/git-guardrails/`) that runs as policy, not as a prompt the agent can talk itself out of. Everything else in this repo — rules, skills — is advisory, same as every competitor's.

---

## Install as a Cursor plugin (Teams/Enterprise)

This repo ships a valid Cursor plugin manifest (`.cursor-plugin/marketplace.json`),
so a **Teams/Enterprise** admin can import it directly without going through the
public marketplace:

**Dashboard → Plugins → Import from Repo** → `SID-SURANGE/cursor-team-ops`, then
enable the plugins you want (currently: 🛡️ **[Git Guardrails](plugins/git-guardrails/)**
— blocking hooks for dangerous git pushes, destructive DB migrations, and
copyleft-licensed dependencies, stopped before they run).

Restart Cursor after installing.

> **Not on Teams/Enterprise, or not an admin?** "Import from Repo" is a
> Teams/Enterprise-admin-only feature in Cursor — it isn't available to
> individual accounts, and this plugin has **not been submitted to Cursor's
> public marketplace**, so it will not show up if you search the Marketplace
> browser. For everyone else, [Install via scripts](#install-via-scripts-alternative)
> below is the actual working path — same rules, skills, and hooks, installed
> via `install.sh`/`install.ps1` instead of the plugin system.

---

## How it works (script install)

```text
~/.cursor/                          your-repo/.cursor/
├── rules/                          ├── rules/
│   ├── core-development.mdc        │   ├── core-development.mdc   ← team rules
│   ├── git-safety.mdc              │   ├── git-safety.mdc
│   ├── agent-behavior.mdc          │   ├── agent-behavior.mdc
│   ├── security-basics.mdc         │   ├── security-basics.mdc
│   ├── documentation.mdc           │   ├── documentation.mdc
│   ├── transaction-atomicity.mdc   │   ├── transaction-atomicity.mdc
│   ├── architectural-drift.mdc     │   ├── architectural-drift.mdc
│   └── telemetry-standards.mdc     │   └── project-context.mdc    ← yours to edit
├── skills/  (21 skills)            ├── skills/  (21 skills)
├── hooks/                          ├── commands/
│   ├── git-guard.sh                │   ├── pr.md
│   ├── db-migration-guard.sh       │   ├── review.md
│   ├── license-gatekeeper.sh       │   ├── fix-issue.md
│   └── session-context.sh          │   └── handoff.md
├── hooks.json                      └── hooks.json  (optional)
└── .team-ops-version
      ↑ install.sh                        ↑ sync-project.sh
```

---

## Install via scripts (alternative)

Use this if you're not on a Cursor plan with plugin support, or you want the
skills and rules symlinked into `~/.cursor/` directly. Same artefacts, manual
distribution.

### 1 — Install on your machine (once)

**macOS / Linux / Git Bash on Windows**

```bash
git clone https://github.com/SID-SURANGE/cursor-team-ops ~/cursor-team-ops
cd ~/cursor-team-ops
bash install.sh
```

**Windows — native PowerShell**

```powershell
git clone https://github.com/SID-SURANGE/cursor-team-ops $HOME\cursor-team-ops
cd $HOME\cursor-team-ops
.\install.ps1
```

> Restart Cursor after install.

**Choosing what gets installed.** By default (`standard` profile) `install.sh` /
`install.ps1` install every rule and every skill **except** the requirements/consulting
cluster (`requirements-qa`, `requirements-synthesis`, `spec-driven-development`,
`architecture-decision-records`) — those serve BRD-heavy, client-facing workflows most
day-to-day engineering teams don't need loaded by default. Pass a profile or an explicit
allowlist to change what installs:

```bash
bash install.sh --profile=minimal      # 3 always-on rules only, no skills
bash install.sh --profile=full         # everything, including the requirements/consulting cluster
bash install.sh --rules=core-development.mdc,git-safety.mdc --skills=commit-message
```

```powershell
.\install.ps1 -InstallProfile minimal
.\install.ps1 -InstallProfile full
.\install.ps1 -Rules core-development.mdc,git-safety.mdc -Skills commit-message
```

Fewer installed rules/skills means less always-scanned context on every Cursor
session — pick `minimal` if you mainly want the git-safety and security guardrails
without the full skill library, or `full` if your team does client requirements/BRD
work and wants that cluster loaded too. `sync-project.sh` / `sync-project.ps1` (step 2
below) accept the same `--profile=` / `--rules=` / `--skills=` flags.

### 2 — Set up a repo (per project)

```bash
cd /path/to/your/repo
bash ~/cursor-team-ops/bootstrap-project.sh   # scaffolds AGENTS.md + commands
bash ~/cursor-team-ops/sync-project.sh         # copies rules + skills into .cursor/
# bash ~/cursor-team-ops/sync-project.sh --profile=minimal   # or pick a smaller profile
```

```powershell
# Windows PowerShell — run from your repo directory
cd C:\path\to\your\repo
bash "$HOME/cursor-team-ops/bootstrap-project.sh"
& "$HOME\cursor-team-ops\sync-project.ps1"
```

Then reload Cursor → `Ctrl+Shift+P` → **Developer: Reload Window** → check **Settings → Rules, Commands**.

### 3 — Commit and share with your team

```bash
# Edit these for your project first
nano AGENTS.md
nano .cursor/rules/project-context.mdc

git add .cursor/ AGENTS.md
git commit -m "chore: add cursor-team-ops baseline"
git push
# teammates get it on next git pull — no install needed beyond step 1
```

---

## Rolling out to a team

```text
Team lead                           Each developer
──────────                          ──────────────
1. git clone cursor-team-ops        1. git clone cursor-team-ops
2. bash install.sh  (once)          2. bash install.sh  (once)
3. bootstrap-project.sh + sync      3. git pull  (gets .cursor/ from repo)
4. edit AGENTS.md                   4. reload Cursor  ✓
5. git push
```

See [TEAMS.md](TEAMS.md) for complete examples: web app team, API team, monorepo.

---

## Rules

Five rules apply to every file in every session. Three additional rules apply conditionally based on file type.

**Always-on**

| Rule | Enforces |
|------|---------|
| `core-development` | Minimal diffs · match style · no placeholders · no over-engineering |
| `git-safety` | No force-push main · no `--no-verify` · commit only when asked |
| `agent-behavior` | Read before edit · use tools · concise output · no preamble |
| `security-basics` | No secrets in code · warn before staging sensitive files |
| `documentation` | Precise prose · no invented requirements · cite existing content |

**Conditional (file-type scoped)**

| Rule | Scope | Enforces |
|------|-------|---------|
| `transaction-atomicity` | `*.ts/.js/.py/.go/.rb/.java` | Multi-step DB writes must use explicit transaction wrappers |
| `architectural-drift` | `*.ts/.js/.py/.go/.java` | No cross-domain imports into private paths; defers to `.deprc.json` |
| `telemetry-standards` | `*.ts/.js/.py/.go/.java` | Structured logging objects required; plain string log calls blocked |

---

## Skills

Skills fire automatically when the agent detects a trigger phrase.

**Core skills** — installed by default (`standard` profile) unless marked otherwise

| Skill | Say this to trigger it | What it does |
|-------|----------------------|-------------|
| `onboarding` | *"I'm new"* / *"orient me"* / *"onboard me"* | First-day orientation — maps repo structure, active rules/skills, and a first-task checklist |
| `pre-commit-check` | *"commit this"* / *"create a commit"* | Audits staged changes for secrets, debug code, and unrelated files before committing |
| `commit-message` | *"write a commit message"* / *"conventional commit"* | Produces a Conventional Commits-compliant message inferred from the staged diff |
| `pr-summary` | *"open a PR"* / *"push and PR"* | Creates a PR with title, summary, and test plan from all commits on the branch |
| `minimal-diff-review` | *"review my changes"* / *"check the diff"* | Reviews changes for scope creep, convention drift, and quality issues |
| `pr-review-canvas` | *"review canvas"* / *"map this PR"* | Groups PR changes by purpose, flags risky sections, and produces a reviewer map |
| `requirements-qa` 🎓 *(full profile)* | *(auto — when working in BRD / docs / requirements folders)* | Flags invented content, conflicts, and open questions in requirements documents |
| `architecture-decision-records` 🎓 *(full profile)* | *"create an ADR"* / *"document this decision"* | Captures architectural decisions in a standard ADR template |
| `deslop` | *"deslop"* / *"clean this up"* / *"remove dead code"* | Strips narrating comments, dead imports, and pointless try/catch blocks |
| `sync-docs-after-edit` | *"sync docs"* / *"did my change break any docs?"* | Scans all markdown files after code changes and flags stale or contradicted docs |
| `document-this` | *"document this"* / *"add a why-comment"* | Adds why-only comments that explain intent and constraints, not what the code does |
| `write-changelog` | *"write a changelog entry"* / *"update CHANGELOG"* | Generates a Keep-a-Changelog entry from commit history |
| `handoff` | *"generate handoff"* / *"close session"* | Documents progress, root causes, failed attempts, and next steps for session handoff — every claim is evidence-tagged (verified / committed-unreviewed / unverified) so a later session can't mistake an untested assertion for a settled fact |
| `commit-history-audit` | *"audit my commits"* / *"check commit history before PR"* | Audits all commits on the branch for WIP markers, wrong convention, overlength subjects, and merge commits that should be squashed. Self-calibrates to the repo's own commit style — never imposes Conventional Commits on a free-form repo. |
| `release-readiness` | *"am I ready to release"* / *"can I ship this"* / *"is this ready to merge"* | Detects workflow mode (formal release with tags vs. continuous deployment from main) and runs the matching checklist — 4 gates for CD teams, 8 gates for versioned projects. |
| `env-drift-check` | *"env drift"* / *"why does it work locally but not in CI"* | Cross-references `.env.example` keys vs. code, runtime version across `.nvmrc`/CI matrix/Docker, CI secret coverage, and Docker lockfile consistency. |

### Community skills

| Skill | Triggered by | What it does |
|-------|-------------|-------------|
| `workflow-from-chats` | *"make this a skill"* | Turns a repeated conversation pattern into a committable `SKILL.md` |
| `spec-driven-development` 🎓 *(full profile)* | *"write a spec"* / *"spec this out"* | Writes a structured spec before any code is touched |
| `security-hardening` | *"security review"* / *"harden this"* | Reviews code against OWASP Top 10 patterns |
| `ci-cd-pipeline` | *"set up CI"* / *"fix the pipeline"* | Scaffolds or repairs a quality-gate pipeline with lint, tests, build, and security audit |
| `requirements-synthesis` 🎓 *(full profile)* | *"synthesize these requirements"* | Ingests PDFs, DOCX, and other client docs into a single structured requirements draft |

🎓 = part of the requirements/consulting cluster — skipped under the default `standard` profile, install with `--profile=full` or an explicit `--skills=` allowlist.

See [skills/community/ATTRIBUTIONS.md](skills/community/ATTRIBUTIONS.md) for full attribution details. [Contribute a skill →](CONTRIBUTING.md)

> **Skills vs. commands** — Skills are auto-triggered by the agent. Commands (`/pr`, `/review`, `/fix-issue`, `/handoff`) are typed manually with `/` in the agent input.

---

## Hooks

| Hook | Event | Behaviour |
|------|-------|-----------|
| `git-guard.sh` | `beforeShellExecution` | **Blocks** direct pushes and force-pushes to main/master, and `rm -rf` on `/`/`~`/`/home`/`/root` · **asks** before force-push to other branches, hard reset, `--no-verify`/`--no-gpg-sign` |
| `db-migration-guard.sh` | `beforeShellExecution` (on `git commit`) | **Asks** before commits with DROP COLUMN, NOT NULL without default, non-CONCURRENT index, DROP TABLE, TRUNCATE — these matter most at production scale, so it confirms rather than blocking outright |
| `license-gatekeeper.sh` | `beforeShellExecution` (on `git commit`) | **Asks** before commits adding GPL/AGPL/LGPL/SSPL/EUPL licensed packages — only relevant if you're distributing commercially |
| `session-context.sh` | `sessionStart` | Checks for kit version drift and an in-progress session handoff. Its `additional_context` output currently doesn't reach the agent due to a confirmed, unresolved Cursor bug — `rules/agent-behavior.mdc` carries the working fallback. See [hooks/README.md](hooks/README.md). |

See [hooks/README.md](hooks/README.md) for schema reference, testing guide, and how to add project-level hooks.

---

## Keeping in sync

```bash
# When the kit releases a new version
cd ~/cursor-team-ops && git pull
bash install.sh                          # update your machine
bash sync-project.sh /path/to/your/repo  # update the repo
git add .cursor/ && git commit -m "chore: sync cursor-team-ops to vX.Y.Z" && git push
# teammates get the update on next git pull
```

The `session-context.sh` hook prints the active kit version at every session start — mismatches are visible immediately.

---

## Cursor Settings UI note

**Settings → Rules, Commands** shows **project** files only (`<repo>/.cursor/`). Machine-level files (`~/.cursor/`) are active but not listed in the panel — this is expected. Run `sync-project.sh` in the repo to make rules and skills appear in Settings.

---

## Contributing

Community skills are welcome. Rules, hooks, and install scripts are maintainer-only.

See [CONTRIBUTING.md](CONTRIBUTING.md) for the quality bar, `SKILL.md` format, and submission steps.

---

## Governance

- **Core changes** — PR + `CHANGELOG.md` entry, maintainer approval
- **Community skills** — PR reviewed against the quality bar in `CONTRIBUTING.md`
- **Quarterly review** — trim rules the agent ignores; promote proven community skills to core
- **Versioning** — tagged releases; `sessionStart` hook prints the active version

---

## Attributions

One core skill (`architecture-decision-records`) was inspired by [awesome-cursor-skills](https://github.com/spencerpauly/awesome-cursor-skills) (Spencer Pauly). Three community skills were informed by [agent-skills](https://github.com/addyosmani/agent-skills) (Addy Osmani, MIT). No text was copied from either source. Full details: [skills/community/ATTRIBUTIONS.md](skills/community/ATTRIBUTIONS.md).

> This kit is **unofficial** and not affiliated with or endorsed by Anysphere (Cursor). "Cursor" is a trademark of Anysphere, Inc.
