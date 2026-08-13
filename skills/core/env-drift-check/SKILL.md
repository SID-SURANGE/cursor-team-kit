---
name: env-drift-check
description: Detect environment drift — mismatches between .env.example, CI environment matrix, Docker base images, and the lockfile runtime — so "works on my machine" failures are caught before they hit staging or production. Triggered by "env drift", "check my environment", "why does it work locally but not in CI", "env-drift-check", "environment mismatch".
disable-model-invocation: true
---

# Skill: env-drift-check

## Purpose

Environment drift is the gap that opens slowly between the four sources of truth for how a project runs: what variables are declared, what runtime the lockfile was resolved against, what the CI matrix specifies, and what the Docker image actually contains. Each source drifts independently. This skill reads all four, cross-references them, and reports concrete mismatches — not generic advice about using `.env.example`.

This is distinct from environment *setup* (use `ci-cd-pipeline` for that). This skill detects drift that has accumulated in a working project over time.

## Trigger phrases

- "env drift"
- "check my environment"
- "why does it work locally but not in CI"
- "env-drift-check"
- "environment mismatch"
- "is my environment consistent"
- "why is CI failing but tests pass locally"
- "check environment consistency"

## Steps

### 1. Discover what exists

Run these in parallel to map the environment landscape before checking for drift:

```bash
# Variable declarations
ls .env.example .env.sample .env.template .env.defaults 2>/dev/null

# Lockfiles and runtime manifests
ls package-lock.json yarn.lock pnpm-lock.yaml poetry.lock Pipfile.lock Gemfile.lock Cargo.lock go.sum 2>/dev/null

# Runtime version declarations
cat .nvmrc 2>/dev/null
cat .node-version 2>/dev/null
cat .python-version 2>/dev/null
cat .ruby-version 2>/dev/null
cat .tool-versions 2>/dev/null    # asdf
cat .mise.toml 2>/dev/null        # mise

# CI configuration
ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml .circleci/config.yml .buildkite/pipeline.yml bitbucket-pipelines.yml 2>/dev/null

# Container
ls Dockerfile docker-compose.yml docker-compose.yaml compose.yml 2>/dev/null
```

If none of these exist, say: "No environment artefacts found. This project may not have formalised environment configuration yet — consider adding a `.env.example` and pinning your runtime version."

---

### 2. Check A — Variable key drift (.env.example vs. reality)

#### 2a. Extract declared keys from .env.example (or equivalent)

```bash
grep -v "^\s*#" .env.example | grep -v "^\s*$" | cut -d= -f1 | sort
```

#### 2b. Extract keys referenced in application code

```bash
# Node/JS/TS
grep -rE "process\.env\.[A-Z_]+" --include="*.js" --include="*.ts" --include="*.mjs" src/ app/ lib/ 2>/dev/null | grep -oE "process\.env\.[A-Z_]+" | sort -u | sed 's/process\.env\.//'

# Python
grep -rE "os\.environ(\[|\.get)\[?['\"]([A-Z_]+)" --include="*.py" . 2>/dev/null | grep -oE "['\"][A-Z_]+" | tr -d "'" | tr -d '"' | sort -u

# Go
grep -rE 'os\.Getenv\("[A-Z_]+"\)' --include="*.go" . 2>/dev/null | grep -oE '"[A-Z_]+"' | tr -d '"' | sort -u
```

#### 2c. Cross-reference

- Keys in `.env.example` but not referenced in code → **STALE** (probably safe to remove)
- Keys referenced in code but absent from `.env.example` → **UNDOCUMENTED** (missing from onboarding guide; breaks new dev setup)
- Report both, but only **UNDOCUMENTED** is a potential blocker

---

### 3. Check B — Runtime version drift

#### 3a. Read the declared runtime version

Sources, in priority order:

| File | How to read |
|------|-------------|
| `.nvmrc` / `.node-version` | Read directly — single version string |
| `.python-version` | Read directly |
| `.tool-versions` (asdf) | Parse `node X.Y.Z` or `python X.Y.Z` lines |
| `.mise.toml` | Parse `[tools]` section |
| `package.json` → `engines.node` | Parse `"node": ">=20"` |
| `pyproject.toml` → `[tool.poetry.dependencies]` | Parse `python = "^3.11"` |

#### 3b. Read the lockfile-implied runtime

```bash
# Node — check the lockfile format version (implies minimum Node version)
head -5 package-lock.json 2>/dev/null    # "lockfileVersion": 3 → Node ≥18

# Python — check requires-python from poetry.lock or Pipfile.lock
grep "python_requires\|python-requires\|requires_python" poetry.lock Pipfile.lock 2>/dev/null | head -5
```

#### 3c. Read the CI matrix runtime

```bash
cat .github/workflows/*.yml 2>/dev/null | grep -E "node-version|python-version|ruby-version|java-version" | head -20
```

#### 3d. Read the Docker base image runtime

```bash
grep "^FROM" Dockerfile 2>/dev/null
```

Map the image tag to a runtime version:

- `node:22-alpine` → Node 22
- `python:3.12-slim` → Python 3.12
- `node:lts` → resolve LTS at time of last pull (flag as imprecise — prefer a pinned version)

#### 3e. Cross-reference all four sources

Produce a version matrix:

| Source | Version |
|--------|---------|
| `.nvmrc` | 22.3.0 |
| `package.json` engines | >=20 |
| CI matrix | 20, 22 |
| Docker base | node:lts (imprecise) |

Flag any mismatch where a fixed version in one source falls outside the range or differs from another fixed version.

---

### 4. Check C — CI environment variable coverage

For each CI workflow file found, extract env vars passed to the job:

```bash
grep -E "^\s+(env:|[A-Z_]+:)" .github/workflows/*.yml 2>/dev/null | grep -v "^\s*#"
```

Cross-reference against `.env.example` keys:

- Keys in `.env.example` marked as required (no default value set, i.e. `KEY=` with empty value) but absent from any CI `env:` block or secrets reference → **CI GAP**: these jobs may fail silently if the key is needed at runtime
- Keys in CI `env:` that are not in `.env.example` → **CI-ONLY KEY**: document it or add it to `.env.example`

---

### 5. Check D — Docker vs. lockfile consistency

If a `Dockerfile` exists and a lockfile exists:

```bash
# Does the Dockerfile copy the lockfile and use it?
grep -E "COPY.*lock|npm ci|pip install --require-hashes|poetry install --no-root" Dockerfile 2>/dev/null
```

- `npm install` (not `npm ci`) in Dockerfile → **DRIFT RISK**: ignores lockfile, installs latest matching semver
- `pip install -r requirements.txt` without a hash-pinned lockfile → **DRIFT RISK**
- Lockfile copied but no `npm ci` / equivalent → **DRIFT RISK**
- `npm ci` or `poetry install` used with lockfile copied → **PASS**

---

### 6. Produce the drift report

Output in this format:

```markdown
## Environment Drift Report — <project-name>

### A. Variable Key Drift

| Key | Status | Action |
|-----|--------|--------|
| DATABASE_URL | ✅ Declared + used | — |
| STRIPE_WEBHOOK_SECRET | ⚠️ UNDOCUMENTED | Add to .env.example |
| OLD_REDIS_URL | ⚠️ STALE | Remove from .env.example (not referenced in code) |
| CI-only: GH_TOKEN | ℹ️ CI-ONLY | Not in .env.example — document if needed for local dev |

**UNDOCUMENTED keys (missing from .env.example):** 1
**STALE keys (in .env.example but unused):** 1

---

### B. Runtime Version Matrix

| Source | Version | Status |
|--------|---------|--------|
| .nvmrc | 22.3.0 | ✅ |
| package.json engines | >=20 | ✅ compatible |
| CI matrix | 20, 22 | ⚠️ CI tests Node 20 but .nvmrc pins 22.3.0 — local dev and one CI matrix arm differ |
| Docker base | node:lts | ⚠️ Imprecise tag — pin to node:22-alpine for reproducibility |

**Drift detected:** CI tests against Node 20 while local dev uses Node 22.3.0.

---

### C. CI Environment Variable Coverage

| .env.example Key | In CI env/secrets | Status |
|------------------|-------------------|--------|
| DATABASE_URL | ✅ via ${{ secrets.DATABASE_URL }} | — |
| STRIPE_KEY | ❌ Not found in any workflow | ⚠️ CI GAP |

---

### D. Docker Lockfile Consistency

| Check | Status |
|-------|--------|
| Lockfile copied into image | ✅ |
| `npm ci` used (not `npm install`) | ❌ Uses `npm install` — lockfile ignored at build time |

---

### Summary

| Check | Status |
|-------|--------|
| A. Variable key drift | ⚠️ 1 undocumented, 1 stale |
| B. Runtime version drift | ⚠️ CI/local mismatch on Node version |
| C. CI env coverage | ⚠️ STRIPE_KEY missing from CI |
| D. Docker lockfile | ❌ npm install used instead of npm ci |

**Overall: DRIFT DETECTED — 4 issues found (1 blocking, 3 advisory)**

### Remediation

**[BLOCKING] D — Docker uses `npm install` instead of `npm ci`**
Change line N of Dockerfile: `RUN npm install` → `RUN npm ci`
This ensures the Docker build uses exactly the versions in package-lock.json.

**[ADVISORY] A — STRIPE_WEBHOOK_SECRET undocumented**
Add to .env.example: `STRIPE_WEBHOOK_SECRET=` (with a comment explaining where to get it)

**[ADVISORY] B — Pin Docker base image**
Change `FROM node:lts` → `FROM node:22-alpine` to match .nvmrc

**[ADVISORY] C — STRIPE_KEY missing from CI**
Add to your workflow env block or GitHub Secrets and reference it as `${{ secrets.STRIPE_KEY }}`
```

**Blocking vs. advisory:**

- **BLOCKING**: Docker ignores lockfile (`npm install` instead of `npm ci` / `poetry install`) — build reproducibility is broken
- **ADVISORY**: version mismatches, undocumented keys, stale keys, CI coverage gaps — worth fixing, do not block

---

### 7. Offer next steps

After the report:

> "Would you like me to fix the blocking issue in the Dockerfile, add missing keys to `.env.example`, or update the CI workflow to pin the runtime version?"

Apply fixes only with explicit confirmation per item.

## Output

- Four-section drift report (variables, runtime, CI coverage, Docker)
- A summary table with per-check status
- A BLOCKING or ADVISORY label per finding
- Specific one-line remediation for each issue

## Notes

- This skill is read-only by default. It reports drift; it does not modify `.env.example`, `Dockerfile`, or CI workflows unless the user confirms.
- If `.env.example` does not exist but `.env` is committed (a security risk), flag it immediately: "`.env` appears to be committed to the repository — this may contain real secrets. Check `.gitignore` and rotate any exposed values."
- For monorepos: ask "Which package or service should I check?" and scope all checks to that subdirectory's artefacts.
- Pairs with: `ci-cd-pipeline` (set up CI from scratch), `release-readiness` (run before shipping to catch drift at release time), `security-hardening` (if secrets exposure is detected).
