<img src="logo.svg" alt="Git Guardrails" width="96" align="left" />

# Git Guardrails

[![Cursor Plugin](https://img.shields.io/badge/Cursor-Plugin-black?style=flat-square)](https://github.com/SID-SURANGE/cursor-team-ops)
[![Version](https://img.shields.io/badge/version-1.6.0-6366f1?style=flat-square)](https://github.com/SID-SURANGE/cursor-team-ops/releases)
[![License: MIT](https://img.shields.io/badge/license-MIT-green?style=flat-square)](LICENSE)

**Hooks that intercept dangerous actions before they run — not after.**

Rules and `AGENTS.md` are *advice*: the agent can read them and still do the
thing. Guardrails are *policy*: they run as `beforeShellExecution` hooks and can
return `deny` or `ask`, so a dangerous command either never executes or requires
explicit confirmation first. This plugin ships one hard-blocking hook, two
confirm-before-proceeding hooks, plus the git-safety rule that documents the
intent behind them all.

Universally-destructive actions (force-pushing main, `rm -rf /`) are hard
blocks. Actions that are only *sometimes* wrong — a migration pattern that's
fine on a small table but dangerous at production scale, a copyleft dependency
that only matters if you're distributing commercially — ask for confirmation
instead of overriding a call that's the developer's to make.

## What it does

| Hook | Event | Behaviour |
|------|-------|-----------|
| `git-guard.sh` | `beforeShellExecution` | **Denies** direct pushes to `main`/`master` and force-pushes to `main`/`master`; **asks** before force-push to other branches, `git reset --hard`, and `--no-verify`/`--no-gpg-sign`; **denies** `rm -rf` on `/`, `~`, `/home`, `/root`. |
| `db-migration-guard.sh` | `beforeShellExecution` (on `git commit`) | **Asks** before commits containing risky migration patterns: `DROP COLUMN`, `NOT NULL` without a default, non-`CONCURRENT` index creation, `DROP TABLE`, `TRUNCATE` — these matter most at production scale, so the hook confirms rather than blocking outright. |
| `license-gatekeeper.sh` | `beforeShellExecution` (on `git commit`) | **Asks** before commits that add packages under copyleft licenses (GPL-2/3, AGPL-3, LGPL, SSPL, EUPL) on lockfile changes — only relevant if you're distributing commercially. |

It also installs the `git-safety` rule (`rules/git-safety.mdc`): commit only when
asked, feature-branch discipline that matches the repo's existing convention,
safe amend policy, and commit-message formatting (bash HEREDOC or PowerShell
here-string, whichever fits your shell).

## Why hooks, not just rules

A rule tells the agent *"don't push to main."* A hook makes the push
**physically fail** — or forces a confirmation before it proceeds. When you're
rolling standards out to a team — especially one with juniors or many parallel
agents — advice that can be ignored is not a control. These hooks are the
controls that Cursor's built-in rules and the official skill packs don't
provide.

## Install

**Via Team Marketplace** (Teams/Enterprise): import
`SID-SURANGE/cursor-team-ops` under **Dashboard → Plugins → Import from Repo**,
then enable **Git Guardrails**.

**Via the Marketplace browser**: search for *Git Guardrails* and install.

Restart Cursor after installing so the hooks register.

## Hook protocol

Each hook reads the shell payload on stdin and emits one JSON line:

- `{"permission":"allow"}` — proceed
- `{"permission":"deny","user_message":"…","agent_message":"…"}` — hard block
- `{"permission":"ask","user_message":"…","agent_message":"…"}` — prompt the user

`failClosed` is `false`, so a hook error never blocks legitimate work — it fails
open and allows the command.

## Part of cursor-team-ops

This plugin is one of the [cursor-team-ops](https://github.com/SID-SURANGE/cursor-team-ops)
enforcement plugins. It is also available as plain shell scripts for teams not on
a Cursor plan that supports plugins — see the root repository.

## License

MIT — see [LICENSE](LICENSE).
