<div align="center">

# 🪝 Hooks

[![hooks](https://img.shields.io/badge/hooks-4%20active-3fb950?style=flat-square)](#installed-hooks)
[![events](https://img.shields.io/badge/events-beforeShellExecution%20%7C%20sessionStart-06b6d4?style=flat-square)](#supported-events)

Shell scripts Cursor executes automatically at lifecycle events.
`git-guard.sh` enforces git safety. `db-migration-guard.sh` blocks destructive migrations. `license-gatekeeper.sh` blocks copyleft packages. `session-context.sh` stamps every session with the kit version.

</div>

---

---

## How hooks work

Cursor reads a `hooks.json` file and runs the listed scripts when the matching event fires. Each script receives a JSON payload on stdin and must print a JSON response to stdout.

### hooks.json schema

```json
{
  "version": 1,
  "hooks": {
    "<event>": [
      {
        "command": "<path-to-script>",
        "matcher": "<optional-regex>",
        "failClosed": false
      }
    ]
  }
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `command` | string | ✅ | Path to the script. For machine hooks (`~/.cursor/hooks.json`), paths are relative to `~/.cursor/`. For project hooks (`.cursor/hooks.json`), paths are relative to the repo root. |
| `matcher` | string | ❌ | Regex applied to the event payload before running the script. For `beforeShellExecution`, it matches against the shell command string. If omitted, the script runs on every event of that type. |
| `failClosed` | boolean | ❌ | If `true`, a script crash or non-zero exit blocks the action. If `false` (default), a crash allows the action to proceed. Prefer `false` for guard hooks to avoid locking users out on script errors. |

---

## Supported events

| Event | When it fires | Stdin payload |
|-------|--------------|---------------|
| `beforeShellExecution` | Before the agent runs any shell command | `{"command": "<shell command string>"}` |
| `sessionStart` | When a new Cursor agent session begins | `{}` |

---

## Response format

Scripts must print a single JSON object to stdout and exit 0.

### `beforeShellExecution` responses

| Permission | Effect |
|-----------|--------|
| `allow` | Command proceeds without interruption. |
| `ask` | Cursor pauses and shows `user_message` to the user before continuing. |
| `deny` | Command is blocked. `user_message` is shown to the user; `agent_message` is fed back to the agent. |

```json
{ "permission": "allow" }

{ "permission": "ask",  "user_message": "...", "agent_message": "..." }

{ "permission": "deny", "user_message": "...", "agent_message": "..." }
```

### `sessionStart` responses

Return additional context to inject into the session:

```json
{ "additional_context": "..." }
```

---

## Installed hooks

### `git-guard.sh` — `beforeShellExecution`

Intercepts shell commands that match `git|rm\s+-r` and enforces the team's git-safety rule:

| Command pattern | Action |
|----------------|--------|
| `git push --force` / `-f` to `main` or `master` | **Deny** — blocked outright |
| `git push --force` / `-f` to any other branch | **Ask** — user must confirm |
| `git reset --hard` | **Ask** — user must confirm |
| `git … --no-verify` / `--no-gpg-sign` | **Ask** — user must confirm |
| `rm -rf /` or `rm -rf ~` (root/home) | **Deny** — blocked outright |
| Everything else | **Allow** |

### `db-migration-guard.sh` — `beforeShellExecution`

Intercepts `git commit` commands and scans staged migration files (`.sql`, ORM migration files in standard paths) for destructive patterns:

| Pattern | Action |
|---------|--------|
| `DROP COLUMN` | **Ask** — permanent data loss without a prior deprecation phase |
| `NOT NULL` without `DEFAULT` | **Ask** — full table lock on large tables |
| `CREATE INDEX` without `CONCURRENTLY` | **Ask** — table lock during index build (PostgreSQL) |
| `DROP TABLE` | **Ask** — irreversible without a backup |
| `TRUNCATE` | **Ask** — destroys all rows, bypasses row-level triggers |

These patterns only matter at production scale (locking, zero-downtime deploys) — the hook asks for confirmation rather than blocking, since a small table or side project may not care.

### `license-gatekeeper.sh` — `beforeShellExecution`

Intercepts `git commit` commands and checks staged lockfile/manifest changes for packages with restrictive copyleft licenses (GPL-2/3, AGPL-3, LGPL, SSPL, EUPL). Uses `license-checker` (Node), `pip-licenses` (Python), or `cargo-license` (Rust) where available; falls back to diff inspection. **Asks** for confirmation rather than blocking — license compliance only matters for commercially-distributed proprietary software, not every project.

### `session-context.sh` — `sessionStart`

Reads `~/.cursor/.team-ops-version` and injects a minimal context string with the active kit version and a pointer to Cursor Settings → Rules, Commands for the installed rule/skill list. If `.cursor/session-handoff.md` exists in the repo, its content is appended too (capped at 100 lines to avoid unbounded context growth).

> ⚠️ **Known Cursor bug — this hook's output may not reach the agent.** As of Cursor 3.1.x (confirmed by Cursor staff on their forum, unresolved as of August 2026), the `additional_context` field returned by `sessionStart` hooks is dropped before it reaches the model due to a timing issue between the hook running and the agent session being created. There is no documented workaround, and no ETA for a fix. This hook still runs and exits cleanly, so it's harmless to leave installed, but do not rely on it as the only way session context gets to the agent.
>
> Because of this, `rules/agent-behavior.mdc` has its own **Session continuity** section that tells the agent to check for `.cursor/session-handoff.md` directly at the start of a session, independent of this hook. Rules are injected through a different, currently-reliable path, so that's the mechanism that actually works today. Keep both in place: the hook will start working again for free if/when Cursor fixes the bug, and the rule-based fallback keeps handoffs working regardless.

---

## Adding a new hook

> Hooks are maintainer-only. See [CONTRIBUTING.md](../CONTRIBUTING.md).

1. Write your script in `hooks/<name>.sh`. Add a comment header identifying the event and install path (see existing scripts for the pattern).
2. Make it executable: `chmod +x hooks/<name>.sh`.
3. Add an entry to `hooks.json` under the appropriate event key.
4. Re-run `install.sh` (or `install.ps1`) to push the change to `~/.cursor/`.
5. Test by triggering the event in Cursor and verifying the response.

### Testing a hook locally

```bash
# Simulate a beforeShellExecution call
echo '{"command":"git push --force origin main"}' | bash hooks/git-guard.sh

# Simulate a sessionStart call
bash hooks/session-context.sh
```

Expected: a valid JSON object printed to stdout, exit code 0.

---

## Project-level hooks

You can add a `hooks.json` at the repo root (or `.cursor/hooks.json`) for project-specific guards. Paths in that file are relative to the repo root.

```json
{
  "version": 1,
  "hooks": {
    "beforeShellExecution": [
      {
        "command": ".cursor/hooks/my-project-guard.sh",
        "matcher": "deploy|publish",
        "failClosed": false
      }
    ]
  }
}
```

Project hooks stack with machine hooks — both fire when the matcher matches.
