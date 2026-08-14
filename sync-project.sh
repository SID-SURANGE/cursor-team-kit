#!/usr/bin/env bash
# sync-project.sh — copy team rules and skills into a repo's .cursor/ for Settings UI visibility
# Usage: bash /path/to/cursor-team-ops/sync-project.sh [repo-path] [--profile=minimal|standard|full] [--rules=a,b] [--skills=a,b]
#   minimal  — always-on rules only (agent-behavior, core-development, security-basics), no skills
#   standard — all rules, all skills EXCEPT the requirements/consulting cluster (default)
#   full     — all rules, all skills including the requirements/consulting cluster
#   --rules= / --skills= — explicit comma-separated allowlist, overrides the profile's list
# The requirements/consulting cluster (requirements-qa, requirements-synthesis,
# spec-driven-development, architecture-decision-records) serves BRD-heavy/client-facing
# workflows, not day-to-day engineering hygiene — opt in with --profile=full or --skills=.
# Defaults to current directory. Safe to re-run (overwrites kit files only).

set -euo pipefail

PROFILE="standard"
RULES_OVERRIDE=""
SKILLS_OVERRIDE=""
REPO_DIR=""
for arg in "$@"; do
  case "$arg" in
    --profile=*) PROFILE="${arg#--profile=}" ;;
    --rules=*) RULES_OVERRIDE="${arg#--rules=}" ;;
    --skills=*) SKILLS_OVERRIDE="${arg#--skills=}" ;;
    --*) echo "Unknown argument: $arg" >&2; exit 1 ;;
    *) REPO_DIR="$arg" ;;
  esac
done
REPO_DIR="${REPO_DIR:-$(pwd)}"

MINIMAL_RULES="agent-behavior.mdc,core-development.mdc,security-basics.mdc"
CONSULTING_SKILLS="requirements-qa,requirements-synthesis,spec-driven-development,architecture-decision-records"

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
    standard) [[ ",$CONSULTING_SKILLS," != *",$name,"* ]] ;;
    full) return 0 ;;
    *) echo "Error: unknown profile '$PROFILE' (expected minimal|standard|full)" >&2; exit 1 ;;
  esac
}

KIT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [ ! -d "$REPO_DIR" ]; then
  echo "Error: repo path does not exist: $REPO_DIR" >&2
  exit 1
fi
REPO_DIR="$(cd "$REPO_DIR" && pwd)"

echo "Syncing team kit rules and skills into: $REPO_DIR (profile: $PROFILE)"
echo ""

mkdir -p "$REPO_DIR/.cursor/rules" "$REPO_DIR/.cursor/skills"

shopt -s nullglob

for rule in "$KIT_DIR/rules/"*.mdc; do
  name="$(basename "$rule")"
  if ! rule_allowed "$name"; then
    echo "  [rule]  $name (skipped, profile: $PROFILE)"
    continue
  fi
  cp "$rule" "$REPO_DIR/.cursor/rules/$name"
  echo "  [rule]  $name"
done

for tier in core community; do
  for skill_dir in "$KIT_DIR/skills/$tier/"*/; do
    name="$(basename "$skill_dir")"
    if ! skill_allowed "$name"; then
      echo "  [skill] $name (skipped, profile: $PROFILE)"
      continue
    fi
    rm -rf "$REPO_DIR/.cursor/skills/$name"
    cp -r "$skill_dir" "$REPO_DIR/.cursor/skills/$name"
    echo "  [skill] $name"
  done
done

echo ""
echo "Done. (profile: $PROFILE) Reload Cursor (Developer: Reload Window) and check Settings → Rules, Commands"
echo "with the project tab selected (your repo name)."
echo "Other profiles: bash sync-project.sh [repo-path] --profile=minimal | --profile=full"
