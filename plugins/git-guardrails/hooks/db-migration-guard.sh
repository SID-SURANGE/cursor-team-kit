#!/usr/bin/env bash
# db-migration-guard.sh — warns on commits containing risky migration patterns
# These patterns are only actually dangerous at production scale (locking, zero-downtime
# deploys); on a small table or side project they're often fine, so this asks rather than
# blocks — the developer, not the hook, decides whether the risk applies to them.
# Event: beforeShellExecution (pre-commit check on staged migration files)
# Installed to: ~/.cursor/hooks/db-migration-guard.sh

set -euo pipefail

input=$(cat)

# Extract the command from the JSON payload
extract_command() {
  local raw="$1"
  local result=""
  set +e
  if command -v python3 &>/dev/null; then
    if result=$(python3 -c "import json,sys; print(json.loads(sys.stdin.read()).get('command',''))" <<< "$raw" 2>/dev/null) && [ -n "$result" ]; then
      echo "$result"; set -e; return
    fi
  fi
  if command -v python &>/dev/null; then
    if result=$(python -c "import json,sys; print(json.loads(sys.stdin.read()).get('command',''))" <<< "$raw" 2>/dev/null) && [ -n "$result" ]; then
      echo "$result"; set -e; return
    fi
  fi
  result=$(echo "$raw" | sed -n 's/.*"command"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -1)
  set -e
  echo "$result"
}

raw_cmd=$(extract_command "$input")

# Only act on git commit commands
if ! echo "$raw_cmd" | grep -qE 'git\s+commit'; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

# Find staged migration files
staged_migrations=$(git diff --cached --name-only 2>/dev/null | grep -iE \
  '(migrations?/|migrate/|db/migrate/|alembic/versions/|flyway/|liquibase/).*\.(sql|py|rb|java|ts|js)$|\.sql$' || true)

if [ -z "$staged_migrations" ]; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

violations=""

for file in $staged_migrations; do
  content=$(git diff --cached -- "$file" 2>/dev/null | grep '^+' | grep -v '^+++' || true)

  # DROP COLUMN — data loss, cannot roll back without restoring from backup
  if echo "$content" | grep -iqE 'DROP\s+COLUMN'; then
    violations="${violations}DROP COLUMN in ${file} — permanent data loss if deployed without a prior deprecation phase. "
  fi

  # NOT NULL without DEFAULT — locks entire table on ALTER in most engines
  if echo "$content" | grep -iqE 'NOT\s+NULL' && ! echo "$content" | grep -iqE 'DEFAULT\s+'; then
    violations="${violations}NOT NULL without DEFAULT in ${file} — full table lock on large tables; existing rows will fail. "
  fi

  # CREATE INDEX without CONCURRENT (PostgreSQL) — locks table during index build
  if echo "$content" | grep -iqE 'CREATE\s+INDEX' && ! echo "$content" | grep -iqE 'CONCURRENTLY'; then
    violations="${violations}CREATE INDEX without CONCURRENTLY in ${file} — locks table during build; use CREATE INDEX CONCURRENTLY. "
  fi

  # DROP TABLE — irreversible without a backup
  if echo "$content" | grep -iqE 'DROP\s+TABLE'; then
    violations="${violations}DROP TABLE in ${file} — irreversible; confirm this migration is intentional and the table is unused. "
  fi

  # TRUNCATE — wipes all rows, bypasses row-level triggers
  if echo "$content" | grep -iqE '\bTRUNCATE\b'; then
    violations="${violations}TRUNCATE in ${file} — destroys all rows and bypasses row-level triggers; use DELETE with a WHERE clause if partial removal is intended. "
  fi
done

if [ -n "$violations" ]; then
  msg="Database migration guard found risky patterns: ${violations}These matter most at production scale (locking, zero-downtime deploys) — confirm this is intentional for your table size and deployment context."
  printf '{"permission":"ask","user_message":"%s","agent_message":"%s"}\n' \
    "$(echo "$msg" | sed 's/"/\\"/g')" \
    "$(echo "$msg" | sed 's/"/\\"/g')"
  exit 0
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
