#!/usr/bin/env bash
#
# bump-claude-plugin.sh — bump the trailing revision suffix (-N) of the Claude
# plugin manifest (.claude-plugin/plugin.json). Run as the last step before
# merging a change. Increments the -N counter; adds -1 when the version has none
# (6.1.1-1 -> 6.1.1-2, 6.1.1 -> 6.1.1-1). Only this one manifest is touched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
MANIFEST="${CLAUDE_PLUGIN_MANIFEST:-$REPO_ROOT/.claude-plugin/plugin.json}"

# Return the next version: increment the trailing -N revision, or add -1 if absent.
next_version() {
  local v="$1"
  if [[ "$v" =~ ^(.+)-([0-9]+)$ ]]; then
    printf '%s-%d' "${BASH_REMATCH[1]}" "$((BASH_REMATCH[2] + 1))"
  else
    printf '%s-1' "$v"
  fi
}

bump() {
  local cur next tmp
  cur="$(jq -r '.version' "$MANIFEST")"
  next="$(next_version "$cur")"
  tmp="${MANIFEST}.tmp"
  jq --arg v "$next" '.version = $v' "$MANIFEST" > "$tmp" && mv "$tmp" "$MANIFEST"
  printf '%s: %s -> %s\n' "${MANIFEST#"$REPO_ROOT/"}" "$cur" "$next"
}

# Run only when executed directly — sourcing (e.g. from tests) exposes the
# functions without performing a bump.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
  case "${1:-}" in
    --help | -h)
      echo "Usage: bump-claude-plugin.sh"
      echo "Bumps the -N revision suffix of .claude-plugin/plugin.json (adds -1 if absent)."
      ;;
    "")
      bump
      ;;
    *)
      echo "error: unexpected argument '$1' — run with no arguments to bump" >&2
      exit 1
      ;;
  esac
fi
