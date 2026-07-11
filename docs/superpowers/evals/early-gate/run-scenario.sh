#!/usr/bin/env bash
# Assemble a toy repo for one early-gate eval scenario, run claude -p in it
# (multi-turn via --resume, one turn per existing answer file), save
# stream-json transcripts per turn, print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
DL="$HERE/../decision-log"   # reused slugtool fixtures (read-only)
SCENARIO="${1:?usage: run-scenario.sh <v1..v4> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"

TOY="$(mktemp -d "/tmp/earlygate-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/tests" "$TOY/docs/superpowers/specs"

cp "$DL/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$DL/base/claude.md" "$TOY/CLAUDE.md"
cp "$DL/base/README.md" "$TOY/README.md"
cp "$DL/base/slugtool.py" "$TOY/slugtool.py"
cp "$DL/base/factories.py" "$TOY/tests/factories.py"
cp "$DL/base/test_slugify.py" "$DL/base/test_truncate.py" "$TOY/tests/"

cp "$DL/registries/new-format.md" "$TOY/docs/superpowers/CONTEXT.md"
cp "$DL/registries/spec-stub-core.md"    "$TOY/docs/superpowers/specs/2026-06-20-slug-core-design.md"
cp "$DL/registries/spec-stub-i18n.md"    "$TOY/docs/superpowers/specs/2026-06-24-i18n-slugs-design.md"
cp "$DL/registries/spec-stub-anchors.md" "$TOY/docs/superpowers/specs/2026-06-28-toc-anchors-design.md"

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"

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

for T in 2 3 4; do
  A="$HERE/prompts/answer-${SCENARIO}-t${T}.md"
  [[ -f "$A" ]] || break
  OUT_T="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}-t${T}.jsonl"
  (cd "$TOY" && timeout 1800 claude -p --resume "$SID" "$(cat "$A")" \
      --model sonnet \
      --dangerously-skip-permissions \
      --verbose \
      --output-format stream-json > "$OUT_T" 2>&1) || true
done

echo "$TOY"
