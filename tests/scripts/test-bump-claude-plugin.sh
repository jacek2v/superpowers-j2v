#!/usr/bin/env bash
# Tests for scripts/bump-claude-plugin.sh — the Claude-plugin-only revision bumper.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
SCRIPT_UNDER_TEST="$REPO_ROOT/scripts/bump-claude-plugin.sh"

FAILURES=0
TEST_ROOT="$(mktemp -d)"

cleanup() {
  rm -rf "$TEST_ROOT"
}
trap cleanup EXIT

pass() {
  echo "  [PASS] $1"
}

fail() {
  echo "  [FAIL] $1"
  FAILURES=$((FAILURES + 1))
}

assert_eq() {
  local actual="$1" expected="$2" description="$3"
  if [[ "$actual" == "$expected" ]]; then
    pass "$description"
  else
    fail "$description"
    echo "    expected: $expected"
    echo "    actual:   $actual"
  fi
}

echo "bump-claude-plugin script tests"

# --- Pure increment logic (next_version) ---
# shellcheck source=/dev/null
source "$SCRIPT_UNDER_TEST"

assert_eq "$(next_version "6.1.1-1")" "6.1.1-2" "increments existing -N suffix"
assert_eq "$(next_version "6.1.1")"   "6.1.1-1" "adds -1 when suffix absent"
assert_eq "$(next_version "6.1.1-2")" "6.1.1-3" "increments -2 to -3"
assert_eq "$(next_version "6.1.1-9")" "6.1.1-10" "carries past single digit (9 -> 10)"

# --- Integration: bump a fixture manifest via the CLAUDE_PLUGIN_MANIFEST override ---
run_bump() {
  local version="$1"
  local manifest="$TEST_ROOT/plugin.json"
  printf '{\n  "name": "superpowers",\n  "version": "%s"\n}\n' "$version" > "$manifest"
  CLAUDE_PLUGIN_MANIFEST="$manifest" bash "$SCRIPT_UNDER_TEST" > /dev/null
  jq -r '.version' "$manifest"
}

out="$(run_bump "6.1.1-1")"
assert_eq "$out" "6.1.1-2" "integration: 6.1.1-1 -> 6.1.1-2 written to manifest"

out="$(run_bump "6.1.1")"
assert_eq "$out" "6.1.1-1" "integration: 6.1.1 -> 6.1.1-1 written to manifest"

if [[ "$FAILURES" -eq 0 ]]; then
  echo "All bump-claude-plugin script tests passed"
else
  echo "$FAILURES bump-claude-plugin script test(s) failed"
  exit 1
fi
