#!/usr/bin/env bash
# session-context.sh — injects kit version and last-session handoff as context at session start
# Event: sessionStart
# Installed to: ~/.cursor/hooks/session-context.sh
# hooks.json path: ./hooks/session-context.sh (relative to ~/.cursor/)

VERSION_FILE="$HOME/.cursor/.team-ops-version"
HANDOFF_FILE=".cursor/session-handoff.md"
HANDOFF_MAX_LINES=100

if [ -f "$VERSION_FILE" ]; then
  VERSION=$(tr -d '[:space:]' < "$VERSION_FILE")
  BASE_CONTEXT="Cursor team kit v${VERSION} is active. Installed rules/skills/hooks are visible under Cursor Settings → Rules, Commands."
else
  BASE_CONTEXT="Cursor team kit is active (version file not found — run install.sh to register the version)."
fi

# Inject last-session handoff if it exists in the current working directory, capped to avoid unbounded context growth
if [ -f "$HANDOFF_FILE" ]; then
  HANDOFF_TOTAL_LINES=$(wc -l < "$HANDOFF_FILE")
  if [ "$HANDOFF_TOTAL_LINES" -gt "$HANDOFF_MAX_LINES" ]; then
    HANDOFF=$(head -n "$HANDOFF_MAX_LINES" "$HANDOFF_FILE")
    HANDOFF="${HANDOFF}

[...truncated: showing first ${HANDOFF_MAX_LINES} of ${HANDOFF_TOTAL_LINES} lines. Read ${HANDOFF_FILE} directly for the rest.]"
  else
    HANDOFF=$(cat "$HANDOFF_FILE")
  fi
  CONTEXT="${BASE_CONTEXT}

--- LAST SESSION HANDOFF ---
${HANDOFF}
--- END HANDOFF ---

Resume from the handoff above. Do not re-derive what is already documented there."
else
  CONTEXT="$BASE_CONTEXT"
fi

# Escape for JSON: replace backslashes, then double-quotes, then newlines
ESCAPED=$(printf '%s' "$CONTEXT" | sed 's/\\/\\\\/g; s/"/\\"/g' | awk '{printf "%s\\n", $0}')

printf '{"additional_context": "%s"}\n' "$ESCAPED"
exit 0
