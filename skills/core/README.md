<div align="center">

# 🧠 Core Skills

[![skills](https://img.shields.io/badge/skills-16%20curated-6366f1?style=flat-square)](#skill-reference)
[![tier](https://img.shields.io/badge/tier-core%20%28maintainer%20reviewed%29-a855f7?style=flat-square)](#skill-reference)

Curated, maintainer-reviewed skills — tested on real projects, kept minimal.
Triggered automatically by phrase. No slash command needed.

</div>

---

## How skills work

Each skill is a `SKILL.md` file with YAML frontmatter the agent uses to decide when to load it:

```yaml
---
name: skill-name
description: What it does and what phrases trigger it.
disable-model-invocation: true  # optional — pure procedural skills only
---
```

The agent matches the `description` field against the current task context. When it fires, it reads the full `SKILL.md` and follows the steps inside.

`disable-model-invocation: true` marks a skill as explicit-invoke only — its description is never auto-scanned for relevance, so it costs nothing in the background and only runs when the user (or agent) names it directly. Set this on procedural skills (commit checks, PR creation) and on skills that are large but rarely needed (`release-readiness`, `env-drift-check`). Omit it on open-ended reasoning skills that should surface on their own (debugging, test writing).

Skills are installed flat — both `core/` and `community/` land in `~/.cursor/skills/` and `<repo>/.cursor/skills/`.

---

## Skill reference

### 🧭 `onboarding`

**Say:** *"I'm new"* / *"just joined"* / *"orient me"* / *"onboard me"*

**Use when:** You just cloned the repo and need first-day orientation. The skill maps the repo structure, explains which rules/skills are active, and walks through a first-task checklist so you're productive without reading every file yourself.

---

### 🔍 `pre-commit-check`

**Say:** *"commit this"* / *"create a commit"*

**Use when:** You're about to make a git commit. Before touching `git commit`, this skill scans your staged diff for secrets, debug code, unrelated file changes, and empty staging areas. It also checks your commit message matches the project's convention. Think of it as a last-second sanity check so you don't accidentally push a password or a half-finished change.

---

### 💬 `commit-message`

**Say:** *"write a commit message"* / *"conventional commit"* / *"what should I commit this as"*

**Use when:** You've made changes but aren't sure how to describe them. The skill reads your staged diff, infers the right Conventional Commits type (`feat`, `fix`, `refactor`, etc.) and scope from the changed file paths, and writes a properly formatted message for you — not just a generic AI summary, but one that follows the `type(scope): subject` structure your team expects.

---

### 📬 `pr-summary`

**Say:** *"open a PR"* / *"push and PR"* / *"submit for review"*

**Use when:** Your branch is ready for review. The skill reads every commit in the branch (not just the latest), drafts a clear PR title and summary, writes a test plan checklist, then runs `gh pr create` for you. It handles the push if the branch isn't on the remote yet.

---

### 🔎 `minimal-diff-review`

**Say:** *"review my changes"* / *"check the diff"* / *"look at what I changed"*

**Use when:** You've made a batch of changes and want a quick gut-check before committing or opening a PR. The skill looks for scope creep (changes unrelated to the task), convention drift (style inconsistencies), leftover debug code, and anything that seems off. Good to run after a long session before you commit.

---

### 🗺️ `pr-review-canvas`

**Say:** *"review canvas"* / *"map this PR"*

**Use when:** You're reviewing someone else's PR (or your own large one) and the diff is hard to parse. Instead of reading the raw diff top-to-bottom, this skill groups changes by purpose — new features, bug fixes, refactors, config changes — flags the riskiest sections, and produces a reviewer map so you know where to focus your attention first.

---

### 📋 `requirements-qa`

**Triggers automatically** when you're working in `docs/`, `requirements/`, or BRD files.

**Also say:** *"did we capture this correctly?"* / *"review this requirements doc"*

**Use when:** You're writing or reviewing a requirements, BRD, or discovery document. The skill checks for invented assumptions (things nobody said but got written in), open questions that were never answered, and conflicts between source documents. Useful before handing off requirements to engineering to avoid "we never said that" moments.

---

### 🏛️ `architecture-decision-records`

**Say:** *"create an ADR"* / *"document this decision"*

**Use when:** Your team just made a meaningful technical decision — choosing a database, picking an auth strategy, deciding to deprecate a service — and you want it on record. The skill creates a structured ADR file (Context → Decision → Consequences) so future developers understand why things are the way they are, not just what they are.

---

### 🧹 `deslop`

**Say:** *"deslop"* / *"clean this up"* / *"remove dead code"*

**Use when:** Code has accumulated noise — comments that just describe what the code already says, unused imports, variables that are assigned but never read, empty try/catch blocks that swallow errors silently. The skill strips that clutter without touching logic. Good to run after a feature is complete and working, before the PR goes for review.

---

### 📝 `sync-docs-after-edit`

**Say:** *"sync docs"* / *"did my change break any docs?"* / *"check if docs are up to date"*

**Use when:** You've just changed code — a function signature, a CLI flag, an API endpoint — and you're not sure if the README, CHANGELOG, or other markdown files still reflect reality. The skill scans all `.md` files in the repo and flags anything that contradicts or is stale relative to your changes.

---

### 💡 `document-this`

**Say:** *"document this function"* / *"add comments"* / *"write docstrings"*

**Use when:** A function, class, or module has non-obvious behaviour that would confuse the next developer — a hidden constraint, a subtle invariant, or a workaround for a specific bug. The skill writes *why-comments* (explaining intent and constraints) rather than *what-comments* (narrating the code). It won't add a comment just to have one.

---

### 📋 `write-changelog`

**Say:** *"update changelog"* / *"write a changelog entry"* / *"what changed since last release"*

**Use when:** You're cutting a release and need to update `CHANGELOG.md`. The skill reads the commits since the last release (or a PR range you specify), groups them into Added / Changed / Fixed / Removed sections following Keep-a-Changelog format, and skips internal-only entries (chores, CI, style) that users don't care about.

---

### 🤝 `handoff`

**Say:** *"generate handoff"* / *"close session"* / *"write handoff doc"*

**Use when:** You're finishing a session — especially a long debugging session or multi-day task — and someone else (or future you) needs to pick it up. The skill writes a `HANDOFF.md` capturing what was done, what was tried and failed (and why), what's still open, and the recommended first next step. Unlike a PR summary, it records the *debugging context and failed attempts* that a diff can't show.

---

### 🔬 `commit-history-audit`

**Say:** *"audit my commits"* / *"check commit history before PR"* / *"are my commits clean"*

**Use when:** Your branch has several commits and you want to catch hygiene problems before a reviewer does — WIP markers, messages in the wrong tense, commits that should be squashed, or subjects that are too long. The skill reads the last 50 commits on the base branch first to detect what convention the repo actually uses (Conventional Commits, ticket-prefixed, or free-form), then audits only against that. It never imposes a standard the project hasn't already adopted. Each failing commit gets a specific suggested rewrite and the rebase command to fix it.

---

### 🚦 `release-readiness`

**Say:** *"am I ready to release"* / *"can I ship this"* / *"is this ready to merge"*

**Use when:** You're about to ship — whether that's tagging a release or merging a feature branch to main. The skill first detects which workflow your project uses: if it finds git tags and a version file, it runs a full 8-gate release check (version bumped, CHANGELOG entry, no debug code, feature flags, migration notes, deployment docs, clean tree, up to date). If the project deploys continuously from main with no formal versioning, it runs a lighter 4-gate pre-merge check covering the gates that matter regardless of workflow. The verdict is BLOCK or READY, with specific remediation for each failure.

Explicit-invoke only (`disable-model-invocation: true`) — say the trigger phrase to run it; it doesn't auto-fire.

---

### 🌊 `env-drift-check`

**Say:** *"env drift"* / *"check my environment"* / *"why does it work locally but not in CI"*

**Use when:** Something works locally but breaks in CI or staging, and you suspect an environment mismatch. The skill checks four axes independently: (1) keys referenced in code but missing from `.env.example` (undocumented variables that break new developer setup), (2) runtime version mismatches between `.nvmrc`, the CI matrix, and the Docker base image, (3) required env vars that have no corresponding CI secret or `env:` block, and (4) whether the Dockerfile uses `npm ci` or `poetry install` with the lockfile (vs. `npm install` which silently ignores it). Only the Docker lockfile issue is blocking; everything else is advisory with one-line fixes.

Explicit-invoke only (`disable-model-invocation: true`) — say the trigger phrase to run it; it doesn't auto-fire.

---

## Promoting a community skill to core

A skill in `skills/community/` may be nominated for promotion after:

- 3+ months with no reported issues
- Positive feedback from at least two independent teams
- Clean, minimal `SKILL.md` with no external dependencies

Open a discussion to nominate. See [CONTRIBUTING.md](../../CONTRIBUTING.md).
