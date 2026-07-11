#!/usr/bin/env bash
# Assemble a toy repo for one decision-log eval scenario, run claude -p in it
# (two turns for s4/s5), save stream-json transcripts, print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
SCENARIO="${1:?usage: run-scenario.sh <s1..s6> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"
GATED_REGISTRY="<gated project>/docs/superpowers/CONTEXT.md"

TOY="$(mktemp -d "/tmp/declog-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/tests" "$TOY/docs/superpowers/specs"

cp "$HERE/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$HERE/base/claude.md" "$TOY/CLAUDE.md"
cp "$HERE/base/README.md" "$TOY/README.md"
cp "$HERE/base/slugtool.py" "$TOY/slugtool.py"
cp "$HERE/base/factories.py" "$TOY/tests/factories.py"
cp "$HERE/base/test_slugify.py" "$HERE/base/test_truncate.py" "$TOY/tests/"

case "$SCENARIO" in
  s5)  # real-world old-format registry, copied at run time (never committed)
    cp "$GATED_REGISTRY" "$TOY/docs/superpowers/CONTEXT.md"
    ;;
  s6)  # control: no registry at all
    ;;
  *)
    if [[ "$PHASE" == baseline ]]; then
      cp "$HERE/registries/old-format.md" "$TOY/docs/superpowers/CONTEXT.md"
    else
      cp "$HERE/registries/new-format.md" "$TOY/docs/superpowers/CONTEXT.md"
    fi
    cp "$HERE/registries/spec-stub-core.md"    "$TOY/docs/superpowers/specs/2026-06-20-slug-core-design.md"
    cp "$HERE/registries/spec-stub-i18n.md"    "$TOY/docs/superpowers/specs/2026-06-24-i18n-slugs-design.md"
    cp "$HERE/registries/spec-stub-anchors.md" "$TOY/docs/superpowers/specs/2026-06-28-toc-anchors-design.md"
    ;;
esac

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
case "$SCENARIO" in
  s3|s4|s6) git -C "$TOY" checkout -qb fix/slug-length ;;  # quick fixes: avoid the main-branch-consent confound
esac

(cd "$TOY" && uv sync -q)

SID="$(uuidgen)"
OUT="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${SCENARIO}.md")"
(cd "$TOY" && timeout 1800 claude -p "$PROMPT" \
    --model sonnet \
    --session-id "$SID" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

if [[ "$SCENARIO" == s4 || "$SCENARIO" == s5 ]]; then
  OUT2="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}-turn2.jsonl"
  ANSWER="$(cat "$HERE/prompts/answer-${SCENARIO}.md")"
  (cd "$TOY" && timeout 1800 claude -p --resume "$SID" "$ANSWER" \
      --model sonnet \
      --dangerously-skip-permissions \
      --verbose \
      --output-format stream-json > "$OUT2" 2>&1) || true
fi

echo "$TOY"
