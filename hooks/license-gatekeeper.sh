#!/usr/bin/env bash
# license-gatekeeper.sh — warns on commits adding packages with restrictive copyleft licenses
# License compliance only matters if the project is commercially distributed as proprietary
# software; solo/internal/OSS projects often don't care, so this asks rather than blocks.
# Event: beforeShellExecution (pre-commit check on staged lockfiles)
# Installed to: ~/.cursor/hooks/license-gatekeeper.sh

set -euo pipefail

input=$(cat)

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

# Check for staged lockfile or manifest changes
staged_lockfiles=$(git diff --cached --name-only 2>/dev/null | grep -iE \
  '^(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|Cargo\.lock|go\.sum|poetry\.lock|Pipfile\.lock|Gemfile\.lock|composer\.lock|package\.json|Cargo\.toml|go\.mod|pyproject\.toml|Gemfile)$' || true)

if [ -z "$staged_lockfiles" ]; then
  printf '%s\n' '{"permission":"allow"}'
  exit 0
fi

# Blocked license identifiers (SPDX)
BLOCKED_LICENSES="GPL-2.0|GPL-3.0|AGPL-3.0|LGPL-2.0|LGPL-2.1|LGPL-3.0|SSPL-1.0|EUPL-1.1|EUPL-1.2|OSL-3.0|CPAL-1.0"

violations=""

# Node/JS: use license-checker if available, otherwise grep package-lock.json for known patterns
if echo "$staged_lockfiles" | grep -qE 'package(-lock)?\.json|yarn\.lock|pnpm-lock'; then
  if command -v license-checker &>/dev/null; then
    flagged=$(license-checker --json 2>/dev/null | python3 -c "
import json, sys, re
blocked = r'$BLOCKED_LICENSES'
data = json.load(sys.stdin)
for pkg, info in data.items():
    lic = info.get('licenses', '')
    if re.search(blocked, str(lic), re.IGNORECASE):
        print(f'{pkg}: {lic}')
" 2>/dev/null || true)
    if [ -n "$flagged" ]; then
      violations="${violations}Restricted license(s) detected in Node dependencies: ${flagged}. "
    fi
  else
    # Fallback: grep for license strings in staged package.json changes
    pkg_diff=$(git diff --cached -- package.json 2>/dev/null | grep '^+' | grep -v '^+++' || true)
    if echo "$pkg_diff" | grep -iqE '"license".*"(GPL|AGPL|LGPL|SSPL|EUPL|OSL|CPAL)'; then
      violations="${violations}Possible restricted license in package.json changes (install license-checker for precise analysis). "
    fi
  fi
fi

# Python: use pip-licenses if available
if echo "$staged_lockfiles" | grep -qE 'poetry\.lock|Pipfile\.lock|pyproject\.toml'; then
  if command -v pip-licenses &>/dev/null; then
    flagged=$(pip-licenses --format=json 2>/dev/null | python3 -c "
import json, sys, re
blocked = r'$BLOCKED_LICENSES'
data = json.load(sys.stdin)
for pkg in data:
    lic = pkg.get('License', '')
    if re.search(blocked, lic, re.IGNORECASE):
        print(f'{pkg[\"Name\"]}: {lic}')
" 2>/dev/null || true)
    if [ -n "$flagged" ]; then
      violations="${violations}Restricted license(s) detected in Python dependencies: ${flagged}. "
    fi
  fi
fi

# Rust: use cargo-license if available
if echo "$staged_lockfiles" | grep -qE 'Cargo\.(lock|toml)'; then
  if command -v cargo-license &>/dev/null; then
    flagged=$(cargo license --json 2>/dev/null | python3 -c "
import json, sys, re
blocked = r'$BLOCKED_LICENSES'
data = json.load(sys.stdin)
for pkg in data:
    lic = pkg.get('license', '')
    if re.search(blocked, str(lic), re.IGNORECASE):
        print(f'{pkg[\"name\"]}: {lic}')
" 2>/dev/null || true)
    if [ -n "$flagged" ]; then
      violations="${violations}Restricted license(s) detected in Rust dependencies: ${flagged}. "
    fi
  fi
fi

if [ -n "$violations" ]; then
  msg="License gatekeeper found: ${violations}Packages with GPL, AGPL, LGPL, SSPL, or EUPL licenses may obligate you to open-source proprietary code — this only matters if you're distributing commercially. Confirm this is fine for your project (or check with legal) before proceeding."
  printf '{"permission":"ask","user_message":"%s","agent_message":"%s"}\n' \
    "$(echo "$msg" | sed 's/"/\\"/g')" \
    "$(echo "$msg" | sed 's/"/\\"/g')"
  exit 0
fi

printf '%s\n' '{"permission":"allow"}'
exit 0
