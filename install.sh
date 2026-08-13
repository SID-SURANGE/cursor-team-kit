#!/usr/bin/env bash
# install.sh — symlinks cursor-team-ops into ~/.cursor/
# Usage: bash install.sh [--profile=minimal|standard|full] [--rules=a,b,c] [--skills=a,b,c]
#   minimal  — always-on rules only (agent-behavior, core-development, security-basics), no skills
#   standard — all rules, all skills (default; matches pre-profile behavior)
#   full     — same as standard (all rules/skills always install; profile mainly gates skills)
#   --rules= / --skills= — explicit comma-separated allowlist, overrides the profile's list
# Re-run after git pull to update.

set -euo pipefail

PROFILE="standard"
RULES_OVERRIDE=""
SKILLS_OVERRIDE=""
for arg in "$@"; do
  case "$arg" in
    --profile=*) PROFILE="${arg#--profile=}" ;;
    --rules=*) RULES_OVERRIDE="${arg#--rules=}" ;;
    --skills=*) SKILLS_OVERRIDE="${arg#--skills=}" ;;
    *) echo "Unknown argument: $arg" >&2; exit 1 ;;
  esac
done

MINIMAL_RULES="agent-behavior.mdc,core-development.mdc,security-basics.mdc"

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CURSOR_DIR="$HOME/.cursor"

if [ ! -f "$KIT_DIR/VERSION" ]; then
  echo "Error: VERSION file not found in $KIT_DIR. Is this a complete clone?" >&2
  exit 1
fi

echo "Installing Cursor team kit v$(cat "$KIT_DIR/VERSION") from $KIT_DIR (profile: $PROFILE)"
echo ""

# ── Resolve what to install ────────────────────────────────────────────────────
# rule_allowed/skill_allowed return 0 (install it) or 1 (skip it)
rule_allowed() {
  local name="$1"
  if [ -n "$RULES_OVERRIDE" ]; then
    [[ ",$RULES_OVERRIDE," == *",$name,"* ]]
    return
  fi
  case "$PROFILE" in
    minimal) [[ ",$MINIMAL_RULES," == *",$name,"* ]] ;;
    standard|full) return 0 ;;
    *) echo "Error: unknown profile '$PROFILE' (expected minimal|standard|full)" >&2; exit 1 ;;
  esac
}

skill_allowed() {
  local name="$1"
  if [ -n "$SKILLS_OVERRIDE" ]; then
    [[ ",$SKILLS_OVERRIDE," == *",$name,"* ]]
    return
  fi
  case "$PROFILE" in
    minimal) return 1 ;;
    standard|full) return 0 ;;
    *) echo "Error: unknown profile '$PROFILE' (expected minimal|standard|full)" >&2; exit 1 ;;
  esac
}

# ── Directories ──────────────────────────────────────────────────────────────
mkdir -p "$CURSOR_DIR/rules" "$CURSOR_DIR/skills" "$CURSOR_DIR/hooks"

# Prevent unmatched globs from being passed as literal strings
shopt -s nullglob

# ── Rules ─────────────────────────────────────────────────────────────────────
for rule in "$KIT_DIR/rules/"*.mdc; do
  name="$(basename "$rule")"
  if ! rule_allowed "$name"; then
    echo "  [rule]  $name (skipped, profile: $PROFILE)"
    continue
  fi
  target="$CURSOR_DIR/rules/$name"
  { [ -L "$target" ] || [ -f "$target" ]; } && rm "$target"
  ln -s "$rule" "$target"
  echo "  [rule]  $name"
done

# ── Skills (core + community, both installed flat into ~/.cursor/skills/) ─────
for tier in core community; do
  for skill_dir in "$KIT_DIR/skills/$tier/"/*/; do
    name="$(basename "$skill_dir")"
    if ! skill_allowed "$name"; then
      echo "  [skill/$tier] $name (skipped, profile: $PROFILE)"
      continue
    fi
    target="$CURSOR_DIR/skills/$name"
    { [ -L "$target" ] || [ -d "$target" ]; } && rm -rf "$target"
    ln -s "$skill_dir" "$target"
    echo "  [skill/$tier] $name"
  done
done

# ── hooks.json ────────────────────────────────────────────────────────────────
target="$CURSOR_DIR/hooks.json"
if [ -L "$target" ] || [ -f "$target" ]; then
  # Back up only if it's a real file (not our symlink)
  if [ ! -L "$target" ]; then
    mv "$target" "${target}.bak"
    echo "  [hooks] Backed up existing hooks.json → hooks.json.bak"
  else
    rm "$target"
  fi
fi
ln -s "$KIT_DIR/hooks.json" "$target"
echo "  [hooks] hooks.json"

# ── Hook scripts ──────────────────────────────────────────────────────────────
for script in "$KIT_DIR/hooks/"*.sh; do
  name="$(basename "$script")"
  target="$CURSOR_DIR/hooks/$name"
  { [ -L "$target" ] || [ -f "$target" ]; } && rm "$target"
  ln -s "$script" "$target"
  chmod +x "$script"
  echo "  [hook]  $name"
done

# ── Record version ────────────────────────────────────────────────────────────
cp "$KIT_DIR/VERSION" "$CURSOR_DIR/.team-ops-version"

echo ""
echo "Done. Team kit v$(cat "$KIT_DIR/VERSION") installed to ~/.cursor/ (profile: $PROFILE)"
echo "Other profiles: bash install.sh --profile=minimal | --profile=full"
echo "Or pick exactly what you want: --rules=core-development.mdc,git-safety.mdc --skills=commit-message"
echo "Next: in each repo, run bootstrap-project.sh and sync-project.sh so rules/skills"
echo "      appear in Cursor Settings. Then reload Cursor."
