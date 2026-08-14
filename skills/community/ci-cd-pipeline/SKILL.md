---
name: ci-cd-pipeline
description: Set up or fix a CI/CD pipeline with quality gates — lint, type check, tests, build, security audit, and deployment. Triggered by "set up CI", "fix the pipeline", "add GitHub Actions", "ci-cd-pipeline", "automate deployment", "set up quality gates".
disable-model-invocation: true
attribution: >
  Independently written. CI/CD quality gate patterns and GitHub Actions configuration
  are publicly documented practices. The gate ordering, feedback loop structure, and
  anti-rationalization approach in this skill were informed by patterns in agent-skills
  (github.com/addyosmani/agent-skills, © Addy Osmani, MIT License).
  No text was copied; this file is an original work.
---

# 🚦 Skill: ci-cd-pipeline

## Purpose

CI/CD is the enforcement mechanism for every other team standard — it catches what humans and agents miss, consistently, on every change. Setting it up once protects the entire team permanently. This skill establishes a quality gate pipeline, feeds failures back into the development loop, and documents deployment strategy.

## Trigger phrases

- "set up CI"
- "add GitHub Actions"
- "fix the pipeline"
- "ci-cd-pipeline"
- "automate deployment"
- "set up quality gates"
- "why is CI failing"
- "add a quality gate"

---

## The quality gate pipeline

Every change passes these gates before merge — in order, no skipping:

```
PR opened
    │
    ▼
 Lint  →  Type check  →  Unit tests  →  Build  →  Security audit
    │
    ▼ (all pass)
 Integration tests  →  E2E (if applicable)
    │
    ▼ (all pass)
 Ready for review  →  Merge  →  Deploy to staging  →  Deploy to production
```

**Shift left:** a bug caught in lint costs minutes; the same bug caught in production costs hours. Move checks as early as possible.

---

## Steps

### 1. Read the project first

Before writing any pipeline config:
- Identify the package manager (`npm`, `pnpm`, `yarn`, `pip`, `cargo`, etc.)
- Find the test command, lint command, build command from `package.json` / `Makefile` / `pyproject.toml`
- Check if a CI config already exists (`.github/workflows/`, `.gitlab-ci.yml`, `Jenkinsfile`)
- If one exists, read it fully before modifying

### 2. Create the CI workflow

**GitHub Actions — Node.js (adapt language as needed)**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main]
  push:
    branches: [main]

jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run lint

  typecheck:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npx tsc --noEmit

  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm test -- --coverage

  build:
    runs-on: ubuntu-latest
    needs: [lint, typecheck, test]
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm run build

  security:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-node@v4
        with:
          node-version: '22'
          cache: 'npm'
      - run: npm ci
      - run: npm audit --audit-level=high
```

### 3. Configure branch protection

After the workflow is live, enforce it via branch protection rules:

```
Settings → Branches → main → Branch protection rule:
  ✅ Require status checks to pass before merging
       Add: lint, typecheck, test, build, security
  ✅ Require branches to be up to date before merging
  ✅ Do not allow force pushes
  ✅ Require at least 1 approving review
```

### 4. Feeding CI failures back to the agent

When CI fails, copy the full failure output and pass it back:

```
"The CI pipeline failed with this error:
[paste full error output — do not truncate]
Fix the issue and verify locally before pushing."
```

| Failure type | What the agent should do |
|-------------|--------------------------|
| Lint error | Run `npm run lint --fix`, review unfixable errors, commit |
| Type error | Read the error location, fix the type, do not use `any` |
| Test failure | Follow `systematic-debugging` skill |
| Build error | Check config, dependencies, and env vars |
| Audit finding | `npm audit fix`; for manual fixes, read the advisory first |

### 5. Deployment strategy

Choose based on project risk:

**Low-risk (internal tools, early stage):**
```
merge to main → auto-deploy to production → monitor for 15 min
```

**Standard (most projects):**
```
merge to main → auto-deploy to staging → manual promotion to production
```

**High-risk (regulated, high traffic):**
```
merge to main → staging → canary (5% traffic) → full production
```

**Rollback workflow:**
```yaml
# .github/workflows/rollback.yml
name: Rollback
on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Version/SHA to roll back to'
        required: true
jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: Rollback
        run: echo "Deploy version ${{ inputs.version }} here"
        # Replace with your actual deployment command
```

### 6. Environment and secrets hygiene

```
.env.example     → committed (template, no real values)
.env             → NOT committed (local dev only, in .gitignore)
.env.test        → committed (test config, no real secrets)
CI secrets       → stored in GitHub Secrets (Settings → Secrets)
Production       → stored in deployment platform vault
```

Never share secrets between CI and production. Use separate values.

---

## Pipeline optimisation (when CI exceeds 10 min)

Apply in this order:

| Fix | Impact |
|----|--------|
| Cache dependencies (`actions/cache` or `setup-node cache`) | High |
| Run lint, typecheck, test in parallel jobs | High |
| Use path filters — skip E2E for docs-only PRs | Medium |
| Shard test suite across matrix runners | Medium |
| Move slow tests to a nightly schedule | Low |

---

## Common rationalisations and rebuttals

| Rationalisation | Reality |
|----------------|---------|
| "CI is too slow to run on every PR" | Optimise the pipeline — don't remove the gate. A 5-min pipeline prevents hours of debugging. |
| "This change is trivial, CI will pass" | Trivial changes cause broken builds. The pipeline is fast for trivial changes. |
| "The test is flaky, just re-run it" | Flaky tests mask real bugs. Fix the flakiness — don't re-run and hope. |
| "We'll add CI after launch" | Projects without CI accumulate broken states that get harder to fix under pressure. Set it up on day one. |
| "I disabled the failing check temporarily" | Temporarily disabled checks become permanently ignored. Fix the check or fix the code. |

---

## Output

A working `.github/workflows/ci.yml` (or equivalent for your CI platform) with all quality gates active, plus branch protection settings documented. Deployment strategy documented in `AGENTS.md` or `docs/deployment.md`.

## Guardrails

- Never disable a failing check to make CI green — fix the code or fix the check.
- Never store secrets in workflow files — use the secrets manager.
- Never set up CI for only one branch and call it done — protect `main` with branch rules too.
- If the project already has CI, read it fully before modifying — don't add duplicate jobs.

## Gotchas
- The sample workflow above is a Node.js template — pasting it unmodified into a Python, Go, or Ruby repo passes the checkout step and then fails every job on a missing `package.json`. Always substitute the package manager, install command, and test/lint/build commands actually detected in Step 1.
- Branch protection settings (`Settings → Branches`) aren't configurable via a committed YAML file — they require repo admin access through the GitHub UI or API. Don't imply the workflow file alone enforces them; call out the manual step explicitly.
- A pipeline that passes locally but was never actually triggered (wrong `on:` branch filter, typo'd branch name) reports as "set up" while doing nothing — verify a real PR actually triggers the new checks before calling the setup done.
