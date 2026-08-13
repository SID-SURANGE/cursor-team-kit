---
name: write-changelog
description: Generate a CHANGELOG.md entry from recent commits or a PR range, following Keep-a-Changelog format. Triggered by "update changelog", "add changelog entry", "write-changelog", "what changed since last release".
---

# 📋 Skill: write-changelog

## Purpose
Keep `CHANGELOG.md` honest and current. Teams universally let changelogs rot — this skill drafts the entry from commit history so the human only needs to review and confirm, not write from scratch.

## Trigger phrases
- "update changelog"
- "add changelog entry"
- "write-changelog"
- "what changed since last release"
- "generate a changelog entry"
- "write the changelog for this release"

## Steps

### 1. Determine the range

```bash
# What version are we releasing?
cat VERSION   # or package.json version, pyproject.toml, etc.

# Commits since the last tag
git log $(git describe --tags --abbrev=0)..HEAD --oneline

# If no tags exist
git log --oneline -30
```

Ask the user for the new version number if it is not clear from a VERSION file.

### 2. Categorise commits

Map each commit to a Keep-a-Changelog section:

| Commit type | Section |
|---|---|
| `feat:` | **Added** |
| `fix:` | **Fixed** |
| `refactor:`, `perf:` | **Changed** |
| `docs:` | **Changed** (if user-visible) or skip |
| Removal of a feature | **Removed** |
| `BREAKING CHANGE:` in body | **Changed** with a ⚠️ Breaking prefix |
| `chore:`, `style:`, `test:`, `ci:` | Skip — internal, not user-facing |

Omit commits that are invisible to users (tooling, CI, test-only changes).

### 3. Draft the entry

```markdown
## [VERSION] — YYYY-MM-DD

### Added
- Short description of new capability. (#PR or commit ref)

### Changed
- Short description of changed behaviour. (#PR or commit ref)

### Fixed
- Short description of bug fixed. (#PR or commit ref)

### Removed
- Short description of removed feature. (#PR or commit ref)
```

Rules:
- Each bullet describes the user-visible effect, not the implementation detail.
- Use past tense: "Added", "Fixed", "Removed" — not "Adds", "Fixes".
- Include a PR or commit reference in parentheses when available.
- Omit empty sections entirely.
- Date format: ISO 8601 (`YYYY-MM-DD`).

### 4. Read the existing CHANGELOG.md

```bash
head -40 CHANGELOG.md    # PowerShell: Get-Content CHANGELOG.md -TotalCount 40
```

Confirm the existing format and insert the new entry **at the top**, below the `# Changelog` heading and above the previous release.

### 5. Present and confirm

Show the drafted entry in a code block. Say: "Ready to prepend this to CHANGELOG.md?" Do not write the file until the user confirms.

### 6. Write on confirmation

Prepend the entry to `CHANGELOG.md`. Do not touch any other section.

## Output
A single Keep-a-Changelog section, ready to prepend to `CHANGELOG.md`.

## Notes
- If `CHANGELOG.md` does not exist, create it with the standard header first:
  ```markdown
  # Changelog

  All notable changes to this project will be documented in this file.
  The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).
  ```
- If commits don't follow Conventional Commits, infer categories from the diff or ask the user to classify ambiguous entries.
- Never include `[Unreleased]` sections — write the version and date directly.
