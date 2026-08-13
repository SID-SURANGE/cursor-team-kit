---
name: release-readiness
description: Walk a structured pre-merge or pre-release gate depending on the repo's workflow — detects whether the project uses formal releases (tags, versioning) or continuous deployment from main, then runs the appropriate checklist. Triggered by "am I ready to release", "pre-release check", "release readiness", "release-readiness", "can I ship this", "is this ready to merge".
disable-model-invocation: true
---

# Skill: release-readiness

## Purpose

Most developer teams do not cut formal releases — they merge to main and deploy. A pre-release checklist that assumes git tags, a VERSION file, and a CHANGELOG is useless to them. This skill detects which workflow the project actually uses, then runs the right checklist: a lightweight pre-merge gate for continuous deployment teams, or a full release gate for teams that tag and version.

## Trigger phrases

- "am I ready to release"
- "pre-release check"
- "release readiness"
- "release-readiness"
- "can I ship this"
- "is this ready to tag"
- "is this ready to merge"
- "pre-release gate"

## Steps

If your environment supports spawning a sub-agent (a background/isolated agent that returns only its final output to the main conversation), delegate steps 1-4 to it — running up to 8 gates means multiple diff/grep passes over changed files, which can be sizable and add no value in the main thread once the report is written. If no sub-agent capability is available, run steps 1-4 inline as normal.

### 1. Detect the workflow mode

Run these in parallel:

```bash
# Does the repo use formal versioning?
cat VERSION 2>/dev/null    # PowerShell: Get-Content VERSION -ErrorAction SilentlyContinue
cat package.json 2>/dev/null | grep '"version"'    # PowerShell: (Get-Content package.json -ErrorAction SilentlyContinue) -match '"version"'
cat pyproject.toml 2>/dev/null | grep '^version'    # PowerShell: (Get-Content pyproject.toml -ErrorAction SilentlyContinue) -match '^version'
cat Cargo.toml 2>/dev/null | grep '^version'    # PowerShell: (Get-Content Cargo.toml -ErrorAction SilentlyContinue) -match '^version'

# Does the repo use git tags?
git describe --tags --abbrev=0 2>/dev/null || echo "(no tags)"
# PowerShell: $tag = git describe --tags --abbrev=0 2>$null; if (-not $tag) { $tag = "(no tags)" }
git tag --list | tail -5    # PowerShell: | Select-Object -Last 5

# CHANGELOG location
ls CHANGELOG.md CHANGELOG HISTORY.md RELEASES.md 2>/dev/null    # PowerShell: Get-ChildItem CHANGELOG.md,CHANGELOG,HISTORY.md,RELEASES.md -ErrorAction SilentlyContinue
```

**Classify the repo into one of two modes:**

| Mode | Signal | Checklist to run |
|------|--------|-----------------|
| **Formal release** | Has git tags AND a version file (VERSION, package.json `version`, etc.) | Full release gate (Gates 1–8) |
| **Continuous deployment** | No git tags, or tags are sporadic/auto-generated (e.g. SHA-based), no dedicated version file | Pre-merge gate (Gates 3, 5, 7, 8 only) |

State the detected mode at the top of the report. If ambiguous, ask: "Does this project cut versioned releases with git tags, or does it deploy continuously from main?"

---

### 2. Pre-merge gate *(Continuous deployment mode — runs Gates 3, 5, 7, 8 only)*

Skip version and CHANGELOG gates entirely. Run only:

- **Gate 3** — No debug code in the diff against base branch
- **Gate 5** — Migration notes written if migrations are present
- **Gate 7** — No uncommitted changes
- **Gate 8** — Branch is up to date with base

Report with the header: `## Pre-Merge Readiness — <branch-name>` instead of a version number.

---

### 3. Full release gate *(Formal release mode — runs all 8 gates)*

Evaluate each gate below. Mark each **PASS**, **FAIL**, or **SKIP** (with reason).

Ask the user: "What version are you releasing?" if it cannot be determined from the version file.

#### Gate 1 — Version is bumped

- Read the version from the detected version source(s).
- Compare against the most recent git tag.
- **PASS**: current version is higher than the last tag (semantic version comparison).
- **FAIL**: version matches the last tag — not bumped.
- **SKIP**: no version file found (note it as a gap, do not block).

#### Gate 2 — CHANGELOG entry exists for this version

- Read the top of `CHANGELOG.md` (or equivalent).
- Check whether there is a section header matching the release version (e.g. `## [1.4.0]` or `## 1.4.0`).
- **PASS**: matching section found with at least one bullet point.
- **FAIL**: no section for this version, or section is empty.
- **SKIP**: no CHANGELOG file exists (note it, recommend `write-changelog` skill).

#### Gate 3 — No debug code in the diff

Use the last tag as the diff base in formal release mode; use the base branch (`main`/`master`) in CD mode.

```bash
# Formal release mode
git diff $(git describe --tags --abbrev=0 2>/dev/null)..HEAD -- '*.js' '*.ts' '*.py' '*.go' '*.rb' '*.java' | grep -E "^\+" | grep -iE "console\.log|print\(|debugger|breakpoint\(\)|pdb\.set_trace|binding\.pry|TODO.*release|FIXME.*release|DO NOT MERGE|fmt\.Println"
# PowerShell equivalent (also note $(git describe --tags --abbrev=0 2>$null) for the embedded 2>/dev/null):
# git diff $(git describe --tags --abbrev=0 2>$null)..HEAD -- '*.js' '*.ts' '*.py' '*.go' '*.rb' '*.java' | Select-String -Pattern '^\+' | Select-String -Pattern 'console\.log|print\(|debugger|breakpoint\(\)|pdb\.set_trace|binding\.pry|TODO.*release|FIXME.*release|DO NOT MERGE|fmt\.Println'

# CD mode
git diff main..HEAD -- '*.js' '*.ts' '*.py' '*.go' '*.rb' '*.java' | grep -E "^\+" | grep -iE "console\.log|print\(|debugger|breakpoint\(\)|pdb\.set_trace|binding\.pry|DO NOT MERGE|fmt\.Println"
# PowerShell equivalent:
# git diff main..HEAD -- '*.js' '*.ts' '*.py' '*.go' '*.rb' '*.java' | Select-String -Pattern '^\+' | Select-String -Pattern 'console\.log|print\(|debugger|breakpoint\(\)|pdb\.set_trace|binding\.pry|DO NOT MERGE|fmt\.Println'
```

- **PASS**: no matches.
- **FAIL**: list each matching file and line. Do not block on `console.error` or `console.warn` — those are legitimate.

#### Gate 4 — Feature flags cleaned up

Detect feature flag patterns in the diff since last tag:

```bash
git diff $(git describe --tags --abbrev=0 2>/dev/null)..HEAD | grep -iE "feature_flag|featureFlag|isEnabled|launch_darkly|unleash|flipper|FEATURE_" | grep "^\+"
# PowerShell equivalent:
# git diff $(git describe --tags --abbrev=0 2>$null)..HEAD | Select-String -Pattern 'feature_flag|featureFlag|isEnabled|launch_darkly|unleash|flipper|FEATURE_' | Select-String -Pattern '^\+'
```

- **PASS**: no new feature flag references added in this release, or all flags added in this diff are documented in the CHANGELOG as intentional.
- **WARN** (non-blocking): new flag references found — list them and ask "Are these intentional? If so, confirm they are documented."
- This gate never produces a hard FAIL — flag debt is common; the goal is awareness.

#### Gate 5 — Migration notes written (if applicable)

Check whether the diff includes database migrations, API breaking changes, or config changes:

```bash
# Formal release mode (diff from last tag)
git diff $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --name-only | grep -iE "migration|migrate|schema|alembic|flyway|liquibase"
git log $(git describe --tags --abbrev=0 2>/dev/null)..HEAD --pretty=format:"%s %b" | grep -i "BREAKING CHANGE"
# PowerShell equivalent (also note $(git describe --tags --abbrev=0 2>$null) for the embedded 2>/dev/null):
# git diff $(git describe --tags --abbrev=0 2>$null)..HEAD --name-only | Select-String -Pattern 'migration|migrate|schema|alembic|flyway|liquibase'
# git log $(git describe --tags --abbrev=0 2>$null)..HEAD --pretty=format:"%s %b" | Select-String -Pattern 'BREAKING CHANGE'

# CD mode (diff from base branch)
git diff main..HEAD --name-only | grep -iE "migration|migrate|schema|alembic|flyway|liquibase"
git log main..HEAD --pretty=format:"%s %b" | grep -i "BREAKING CHANGE"
# PowerShell equivalent:
# git diff main..HEAD --name-only | Select-String -Pattern 'migration|migrate|schema|alembic|flyway|liquibase'
# git log main..HEAD --pretty=format:"%s %b" | Select-String -Pattern 'BREAKING CHANGE'
```

- **PASS**: no migrations or breaking changes detected.
- **PASS**: migrations detected AND a migration/upgrade guide exists in `docs/`, `CHANGELOG.md`, or a `MIGRATION.md` file.
- **FAIL**: migrations or breaking changes detected but no migration notes found anywhere.

#### Gate 6 — Deployment documentation is current

Check for a deployment or operations doc:

```bash
ls docs/deployment* docs/deploy* docs/ops* DEPLOY.md OPERATIONS.md runbook* 2>/dev/null
# PowerShell: Get-ChildItem docs/deployment*,docs/deploy*,docs/ops*,DEPLOY.md,OPERATIONS.md,runbook* -ErrorAction SilentlyContinue
```

- If a deployment doc exists: check whether it was modified in this release cycle (since last tag). If the diff includes infra/config/env changes but the deployment doc was NOT touched, flag it.
- **PASS**: no deployment-impacting changes, or deployment doc was updated.
- **WARN** (non-blocking): deployment-impacting changes detected (new env vars, Docker changes, config keys) but deployment doc unchanged.
- **SKIP**: no deployment doc exists — note it as a gap, do not block.

#### Gate 7 — No uncommitted changes

```bash
git status --short
```

- **PASS**: working tree is clean.
- **FAIL**: uncommitted or unstaged changes exist. A release should be cut from a clean working tree.

#### Gate 8 — Branch is up to date with base

```bash
git fetch origin --dry-run 2>&1
git rev-list HEAD..origin/main --count 2>/dev/null   # replace 'main' with detected base branch
# PowerShell: 2>$null
```

- **PASS**: branch is at or ahead of the remote base — nothing to pull.
- **FAIL**: remote has commits the local branch does not — rebase or merge before releasing.

---

### 4. Produce the readiness report

Output in this format:

```markdown
## Release Readiness — v<VERSION>
<!-- or: ## Pre-Merge Readiness — <branch-name> (CD mode) -->

| Gate | Status | Notes |
|------|--------|-------|
| 1. Version bumped | ✅ PASS | v1.4.0 > v1.3.2 (last tag) |
| 2. CHANGELOG entry | ❌ FAIL | No ## [1.4.0] section found |
| 3. No debug code | ✅ PASS | |
| 4. Feature flags | ⚠️ WARN | 2 new flags added — confirm intentional |
| 5. Migration notes | ✅ PASS | No migrations detected |
| 6. Deployment docs | ⚠️ WARN | New env var STRIPE_KEY detected; DEPLOY.md unchanged |
| 7. Clean working tree | ✅ PASS | |
| 8. Branch up to date | ✅ PASS | |

### Verdict: BLOCK — 1 failure must be resolved before releasing.

### Required actions

**Gate 2 — CHANGELOG entry missing**
Run the `write-changelog` skill to generate the entry, or add a `## [1.4.0] — YYYY-MM-DD` section manually.

### Advisory (non-blocking)

**Gate 4 — Feature flags**
New flags in this diff: `FEATURE_NEW_CHECKOUT`, `featureFlagBetaDashboard`
Confirm these are intentional and document them in the CHANGELOG if user-facing.

**Gate 6 — Deployment docs**
`STRIPE_KEY` added to `.env.example` but not mentioned in `DEPLOY.md`.
Consider adding a note so operators know to provision this before deploying.
```

**Verdict rules:**

- Any gate marked **FAIL** → overall verdict is **BLOCK**
- Gates marked **WARN** are advisory — list them but do not block
- Gates marked **SKIP** are gaps — list them as recommendations, do not block
- All gates **PASS** or **WARN/SKIP** only → verdict is **READY TO RELEASE** (formal mode) or **READY TO MERGE** (CD mode)

### 5. Offer next steps

After the report, offer:

> "Would you like me to run `write-changelog` to fix Gate 2, or address another failing gate first?"

Do not cut the tag, push, or deploy automatically.

## Output

- A gate-by-gate status table
- A single BLOCK or READY TO RELEASE verdict
- Specific remediation steps for each FAIL
- Advisory notes for each WARN

## Notes

- This skill reads and reports. It does not write files, commit, tag, or deploy unless the user explicitly asks and triggers the relevant skill (`write-changelog`, `pr-summary`).
- The checklist is intentionally language-agnostic. Gates adapt to what is found — missing artefacts are SKIP, not FAIL, unless they directly prevent a safe release.
- For monorepos: ask the user "Which package or service are we releasing?" and scope all checks to that subdirectory.
- **Why dual-mode matters**: ~60% of developer teams use continuous deployment from main with no formal versioning (GitHub Octoverse, DORA 2024). A skill that assumes git tags and a CHANGELOG fails silently for the majority. CD mode runs the gates that matter for every team (no debug code, migration notes, clean tree, up-to-date branch) without demanding artefacts that most projects don't have.
- Pairs with: `write-changelog` (Gate 2 remediation in formal mode), `commit-history-audit` (run before this skill), `pr-summary` (after READY verdict, to create the PR).
