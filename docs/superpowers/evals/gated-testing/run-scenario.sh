#!/usr/bin/env bash
# Assemble a toy repo for one gated-testing eval scenario, run claude -p in it,
# save the stream-json transcript, and print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCENARIO="${1:?usage: run-scenario.sh <s1..s6> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"

TOY="$(mktemp -d "/tmp/gated-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/docs" "$TOY/tests"

copy_base_py() {  # pyproject variant
  cp "$HERE/base/pyproject-$1.toml" "$TOY/pyproject.toml"
  if [[ "$1" == nopytest ]]; then
    cp -r "$HERE/base/pytest-stub" "$TOY/pytest-stub"
  fi
}

case "$SCENARIO" in
  s1)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    if [[ "$PHASE" == baseline ]]; then
      cp "$HERE/claude-md/baseline.md" "$TOY/CLAUDE.md"
      cp "$HERE/plans/plan-classic.md" "$TOY/docs/plan.md"
    else
      cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
      cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    fi
    ;;
  s2)
    copy_base_py pytest
    cp "$HERE/base/factories-sabotaged.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-runner-claude.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    ;;
  s3)
    copy_base_py pytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/control.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-classic.md" "$TOY/docs/plan.md"
    ;;
  s4)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/base/toy-spec.md" "$TOY/docs/toy-spec.md"
    ;;
  s5)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/base/slugtool.py" "$TOY/slugtool.py"
    cp "$HERE/base/test_slugify.py" "$TOY/tests/test_slugify.py"
    cp "$HERE/base/test_truncate.py" "$TOY/tests/test_truncate.py"
    ;;
  s6)
    copy_base_py nopytest
    cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
    cp "$HERE/claude-md/gated-operator.md" "$TOY/CLAUDE.md"
    cp "$HERE/plans/plan-gated.md" "$TOY/docs/plan.md"
    ;;
  *) echo "unknown scenario: $SCENARIO" >&2; exit 2 ;;
esac

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
git -C "$TOY" checkout -qb feature/slug

if grep -q dependency-groups "$TOY/pyproject.toml"; then
  (cd "$TOY" && uv sync -q)
fi

OUT="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${SCENARIO}.md")"
(cd "$TOY" && timeout 1800 claude -p "$PROMPT" \
    --model sonnet \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

echo "$TOY"
