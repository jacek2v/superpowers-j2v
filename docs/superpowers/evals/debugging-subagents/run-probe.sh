#!/usr/bin/env bash
# Put the systematic-debugging skill into one arm's state (the marketplace
# plugin is a symlink to this checkout), assemble a ledgerlite toy repo, run one
# claude -p probe session in it, save the stream-json transcript, print the toy
# dir path. Each arm swap replaces the whole skill directory, so the tree
# matches the target ref exactly. An EXIT trap restores the feature-branch
# state on every exit path, including a failure.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="<repo>"
SKILL_DIR="skills/systematic-debugging"
BASE_REF="${BASE_REF:-main}"
FEATURE_REF="${FEATURE_REF:-feat/debugging-subagents}"
MODEL="${MODEL:-sonnet}"

PROBE="${1:?usage: run-probe.sh <p1|p2|p3> <red|green> [rep]}"
ARM="${2:?arm: red|green}"
REP="${3:-1}"

# Replace the skill directory with the target ref's version. The removal makes
# this a full sync: git checkout alone leaves files that the ref does not have.
swap_to() {
  # Guard the path, because rm -rf expands variables.
  [[ -n "$REPO" && "$SKILL_DIR" == skills/?* ]] \
    || { echo "refusing: unsafe skill path '$REPO/$SKILL_DIR'" >&2; exit 4; }
  rm -rf "${REPO:?}/${SKILL_DIR:?}"
  git -C "$REPO" checkout "$1" -- "$SKILL_DIR"
}

# Refuse to run on uncommitted skill edits — the arm swap would destroy them.
if ! git -C "$REPO" diff --quiet -- "$SKILL_DIR" \
   || ! git -C "$REPO" diff --cached --quiet -- "$SKILL_DIR"; then
  echo "refusing: uncommitted changes in $SKILL_DIR — commit them first" >&2
  exit 3
fi

# Installed after the dirty check, so it cannot destroy uncommitted skill edits.
trap 'swap_to "$FEATURE_REF"' EXIT

case "$ARM" in
  red)   swap_to "$BASE_REF" ;;
  green) swap_to "$FEATURE_REF" ;;
  *) echo "arm must be red or green" >&2; exit 2 ;;
esac

TOY="$(mktemp -d "/tmp/dbg-eval-${PROBE}-${ARM}-XXXX")"
mkdir -p "$TOY/tests"
cp "$HERE/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$HERE/base/dates.py" "$HERE/base/parse.py" "$HERE/base/report.py" "$TOY/"
cp "$HERE/base/test_report.py" "$TOY/tests/test_report.py"
cp "$HERE/base/run.log" "$TOY/run.log"
if [[ "$PROBE" == p3 ]]; then
  cp "$HERE/base/claude-gated.md" "$TOY/CLAUDE.md"
else
  cp "$HERE/base/claude-classic.md" "$TOY/CLAUDE.md"
fi

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
git -C "$TOY" checkout -qb fix/monthly-report

(cd "$TOY" && uv sync -q)

OUT="$HERE/transcripts/${ARM}-${PROBE}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${PROBE}.md")"
(cd "$TOY" && timeout 2700 claude -p "$PROMPT" \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

# The EXIT trap restores the feature-branch state.
echo "$TOY"
