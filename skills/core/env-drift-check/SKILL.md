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

If your environment supports spawning a sub-agent (a background/isolated agent that returns only its final output to the main conversation), delegate steps 1-6 to it. This phase runs ~15 discovery/grep commands and can produce a lot of intermediate output that has no value once the report is written — only the finished report from step 6 needs to land in the main thread. If no sub-agent capability is available, run steps 1-6 inline as normal.

### 1. Discover what exists

Run these in parallel to map the environment landscape before checking for drift:

```bash
# Variable declarations
ls .env.example .env.sample .env.template .env.defaults 2>/dev/null    # PowerShell: Get-ChildItem .env.example,.env.sample,.env.template,.env.defaults -ErrorAction SilentlyContinue

# Lockfiles and runtime manifests
ls package-lock.json yarn.lock pnpm-lock.yaml poetry.lock Pipfile.lock Gemfile.lock Cargo.lock go.sum 2>/dev/null    # PowerShell: Get-ChildItem package-lock.json,yarn.lock,pnpm-lock.yaml,poetry.lock,Pipfile.lock,Gemfile.lock,Cargo.lock,go.sum -ErrorAction SilentlyContinue

# Runtime version declarations
cat .nvmrc 2>/dev/null    # PowerShell: Get-Content .nvmrc -ErrorAction SilentlyContinue
cat .node-version 2>/dev/null    # PowerShell: Get-Content .node-version -ErrorAction SilentlyContinue
cat .python-version 2>/dev/null    # PowerShell: Get-Content .python-version -ErrorAction SilentlyContinue
cat .ruby-version 2>/dev/null    # PowerShell: Get-Content .ruby-version -ErrorAction SilentlyContinue
cat .tool-versions 2>/dev/null    # asdf — PowerShell: Get-Content .tool-versions -ErrorAction SilentlyContinue
cat .mise.toml 2>/dev/null        # mise — PowerShell: Get-Content .mise.toml -ErrorAction SilentlyContinue

# CI configuration
ls .github/workflows/*.yml .github/workflows/*.yaml .gitlab-ci.yml .circleci/config.yml .buildkite/pipeline.yml bitbucket-pipelines.yml 2>/dev/null    # PowerShell: Get-ChildItem .github/workflows/*.yml,.github/workflows/*.yaml,.gitlab-ci.yml,.circleci/config.yml,.buildkite/pipeline.yml,bitbucket-pipelines.yml -ErrorAction SilentlyContinue

# Container
ls Dockerfile docker-compose.yml docker-compose.yaml compose.yml 2>/dev/null    # PowerShell: Get-ChildItem Dockerfile,docker-compose.yml,docker-compose.yaml,compose.yml -ErrorAction SilentlyContinue
```

If none of these exist, say: "No environment artefacts found. This project may not have formalised environment configuration yet — consider adding a `.env.example` and pinning your runtime version."

---

### 2. Check A — Variable key drift (.env.example vs. reality)

#### 2a. Extract declared keys from .env.example (or equivalent)

```bash
grep -v "^\s*#" .env.example | grep -v "^\s*$" | cut -d= -f1 | sort
```

PowerShell equivalent:

```powershell
Get-Content .env.example | Where-Object { $_ -notmatch '^\s*#' -and $_.Trim() -ne '' } | ForEach-Object { ($_ -split '=')[0] } | Sort-Object
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

PowerShell equivalent (Node/JS/TS):

```powershell
Get-ChildItem src,app,lib -Recurse -Include *.js,*.ts,*.mjs -ErrorAction SilentlyContinue | Select-String -Pattern 'process\.env\.([A-Z_]+)' | ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique
```

PowerShell equivalent (Python):

```powershell
Get-ChildItem -Recurse -Include *.py -ErrorAction SilentlyContinue | Select-String -Pattern "os\.environ(\[|\.get)\[?['\"]([A-Z_]+)" | ForEach-Object { $_.Matches.Groups[2].Value } | Sort-Object -Unique
```

PowerShell equivalent (Go):

```powershell
Get-ChildItem -Recurse -Include *.go -ErrorAction SilentlyContinue | Select-String -Pattern 'os\.Getenv\("([A-Z_]+)"\)' | ForEach-Object { $_.Matches.Groups[1].Value } | Sort-Object -Unique
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
head -5 package-lock.json 2>/dev/null    # "lockfileVersion": 3 → Node ≥18    # PowerShell: Get-Content package-lock.json -TotalCount 5

# Python — check requires-python from poetry.lock or Pipfile.lock
grep "python_requires\|python-requires\|requires_python" poetry.lock Pipfile.lock 2>/dev/null | head -5    # PowerShell: Select-String -Path poetry.lock,Pipfile.lock -Pattern 'python_requires|python-requires|requires_python' -ErrorAction SilentlyContinue | Select-Object -First 5
```

#### 3c. Read the CI matrix runtime

```bash
cat .github/workflows/*.yml 2>/dev/null | grep -E "node-version|python-version|ruby-version|java-version" | head -20
```

PowerShell equivalent:

```powershell
Get-ChildItem .github/workflows -Filter *.yml -ErrorAction SilentlyContinue | Get-Content | Select-String -Pattern 'node-version|python-version|ruby-version|java-version' | Select-Object -First 20
```

#### 3d. Read the Docker base image runtime

```bash
grep "^FROM" Dockerfile 2>/dev/null    # PowerShell: Select-String -Path Dockerfile -Pattern '^FROM' -ErrorAction SilentlyContinue
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

PowerShell equivalent:

```powershell
Get-ChildItem .github/workflows -Filter *.yml -ErrorAction SilentlyContinue | Get-Content | Where-Object { $_ -match '^\s+(env:|[A-Z_]+:)' -and $_ -notmatch '^\s*#' }
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

PowerShell equivalent:

```powershell
Select-String -Path Dockerfile -Pattern 'COPY.*lock|npm ci|pip install --require-hashes|poetry install --no-root' -ErrorAction SilentlyContinue
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

## Gotchas
- The grep-based env-var extraction only catches statically-referenced keys (`process.env.FOO`, `os.environ['FOO']`). A key built dynamically (`process.env[computedName]`, `os.environ.get(f"{prefix}_KEY")`) won't surface — report the extraction as best-effort coverage, not exhaustive, so a clean report isn't read as a guarantee.
- The Docker tag→runtime-version mapping (`node:22-alpine` → Node 22) is a small lookup table — an unfamiliar or custom base image tag should be reported as "unable to determine," never silently guessed at or skipped as if it matched.
- `npm ci` presence in the Dockerfile doesn't guarantee the lockfile is actually copied in first — check both `COPY *lock*` and the install command together; either alone can still mean the build ignores the lockfile.
