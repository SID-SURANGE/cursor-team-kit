<div align="center">

# 🚀 Onboarding Checklist

[![Version](https://img.shields.io/badge/version-1.3.0-6366f1?style=flat-square)](CHANGELOG.md)
[![Platform](https://img.shields.io/badge/platform-macOS%20%7C%20Linux%20%7C%20Windows-06b6d4?style=flat-square)](#1-install-the-kit-on-your-machine-5-min)

**For every developer joining the team.**
Machine install once → bootstrap + sync per repo → done.

</div>

---

---

## 1. Install the kit on your machine (~5 min)

```bash
git clone https://github.com/SID-SURANGE/cursor-team-ops ~/cursor-team-ops
cd ~/cursor-team-ops
bash install.sh
```

**Windows:** Prefer Git for Windows Bash (`.../Git/bin/bash.exe`) or `.\install.ps1` in PowerShell. Avoid WSL `bash` unless you intend to use WSL for all Cursor work — it uses a different `$HOME`.

Restart or reload Cursor after install.

**Verify (machine — filesystem, not Settings UI):**

- [ ] `~/.cursor/rules/` contains eight `.mdc` files (`core-development`, `git-safety`, etc.)
- [ ] `~/.cursor/skills/` contains skill directories, each with `SKILL.md` (`ls ~/.cursor/skills/ | wc -l` shows the count)
- [ ] `~/.cursor/hooks.json` exists
- [ ] `cat ~/.cursor/.team-ops-version` shows the kit version (e.g. `1.6.0`)

These paths are **not** listed in **Settings → Rules, Commands** — that is normal.

---

## 2. Set up each project repo (~3 min per repo)

```bash
cd /path/to/your/repo
bash ~/cursor-team-ops/bootstrap-project.sh
bash ~/cursor-team-ops/sync-project.sh
```

**Windows PowerShell alternative for sync (run from your repo directory):**

```powershell
& "$HOME\cursor-team-ops\sync-project.ps1"
```

Then edit:

- [ ] `AGENTS.md` — project name, key paths, commands, conventions
- [ ] `.cursor/rules/project-context.mdc` — source-of-truth path and project overrides
- [ ] Commit `.cursor/` and `AGENTS.md` if the team should share the setup

**Reload Cursor** (`Ctrl+Shift+P` → **Developer: Reload Window**).

**Verify (project — Settings UI):**

- [ ] Open **Cursor Settings → Rules, Commands**
- [ ] Select the **project** tab (e.g. `briefcast`), not only **User** or **All**
- [ ] **Rules:** team rules + `project-context` (and `CLAUDE` / `AGENTS` if present at repo root)
- [ ] **Skills:** core skills listed (count should match `ls skills/core/ | wc -l` in the kit repo)
- [ ] **Commands:** `/pr`, `/review`, `/fix-issue` (from bootstrap)

**Optional — agent / hooks:**

- [ ] **Settings → Hooks:** `beforeShellExecution`, `sessionStart` (from machine `install.sh`)
- [ ] New chat: session hook may mention kit version

**For existing repos that already have `.cursor/rules/`:**

Run `sync-project.sh` only if team rules/skills are missing. Keep repo-specific rules; add `AGENTS.md` from the template if helpful.

---

## 3. Daily use

| Task | Kit handles via |
|------|----------------|
| First day / new repo | Say "onboard me" or "I'm new" → `onboarding` skill |
| Commit changes | Say "commit this" → `pre-commit-check` skill → then commit |
| Open a PR | Say "create a PR" → `pr-summary` skill |
| Review a diff | Say "review my changes" → `minimal-diff-review` skill |
| Work on BRD/docs | `documentation` rule + `requirements-qa` skill (automatic) |
| End a session | Say "EOD" or "generate handoff" → `handoff` skill (writes `.cursor/session-handoff.md`) |
| Next session start | `sessionStart` hook auto-loads last handoff — Claude resumes with context |
| Try to push to main | `git-guard.sh` hook blocks direct and force pushes to main/master |
| Commit a destructive migration | `db-migration-guard.sh` hook blocks |
| Add a copyleft package | `license-gatekeeper.sh` hook blocks |

---

## 4. Keeping the kit up to date

```bash
cd ~/cursor-team-ops
git pull
bash install.sh
bash sync-project.sh /path/to/each/repo
# Reload Cursor
```

Re-run `sync-project.sh` in every repo you use after pulling kit changes that touch `rules/` or `skills/`.

The `sessionStart` hook shows the active version. If it differs from `git log`, re-run `install.sh`.

---

## 5. Proposing changes to the kit

1. Branch from `main` in the kit repo.
2. Edit rule / skill / hook.
3. Update `CHANGELOG.md` with a bullet under a new version.
4. Bump `VERSION`.
5. Open a PR — at least one kit owner must approve.

Do not edit `~/.cursor/` by hand after install — changes will be overwritten on next `install.sh`. Prefer editing the kit repo and re-running `install.sh` + `sync-project.sh`.

---

## Troubleshooting

| Symptom | Likely cause | Fix |
|---------|----------------|-----|
| `install.sh` succeeded but Settings only shows `CLAUDE` | Only machine install done; UI lists **project** `.cursor/` | Run `bootstrap-project.sh` + `sync-project.sh` in the repo; reload Cursor; select **project** tab in Settings |
| Rules in `~/.cursor/rules/` but not in Settings | Cursor does not enumerate global rule files in that panel | Run `sync-project.sh` in the repo |
| Skills section empty | Skills only in `~/.cursor/skills/` | Run `sync-project.sh` in the repo |
| Windows install went to wrong place | Used WSL `bash` instead of Git Bash | Re-run with Git for Windows Bash or `install.ps1`; check `%USERPROFILE%\.cursor\rules` |
| Hooks not firing | Bash hooks on Windows without Git Bash/WSL | Use Git Bash for agent shell; see README Windows note |
| Kit version file missing | `install.sh` did not complete | Re-run `install.sh`; `cat ~/.cursor/.team-kit-version` |
| Wrong hook path | Project vs user hook roots differ | Project hooks: paths relative to repo root; user hooks: relative to `~/.cursor/` |
