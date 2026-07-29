#!/usr/bin/env bash
# Assemble a feedmix toy repo for one deep-research eval scenario, run
# claude -p in it (multi-turn via --resume, one turn per existing answer
# file), save stream-json transcripts per turn, print the toy dir path.
set -euo pipefail

HERE="${DR_FIXTURE:-$(cd "$(dirname "$0")" && pwd)}"
SCENARIO="${1:?usage: run-scenario.sh <r1|r2|r3|r4> <baseline|green> [rep]}"
PHASE="${2:?phase: baseline|green}"
REP="${3:-1}"

TOY="$(mktemp -d "/tmp/deepresearch-eval-${SCENARIO}-${PHASE}-XXXX")"
mkdir -p "$TOY/tests" "$TOY/docs/superpowers/specs"

cp "$HERE/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$HERE/base/CLAUDE.md" "$TOY/CLAUDE.md"
cp "$HERE/base/README.md" "$TOY/README.md"
cp "$HERE/base/feedmix.py" "$TOY/feedmix.py"
cp "$HERE/base/test_store.py" "$TOY/tests/test_store.py"

cp "$HERE/registries/context.md" "$TOY/docs/superpowers/CONTEXT.md"
cp "$HERE/registries/spec-stub-store.md"  "$TOY/docs/superpowers/specs/2026-07-02-article-store-design.md"
cp "$HERE/registries/spec-stub-export.md" "$TOY/docs/superpowers/specs/2026-07-20-cli-export-design.md"

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"

(cd "$TOY" && uv sync -q)

PROMPT_FILE="$HERE/prompts/prompt-${SCENARIO}.md"
[[ -f "$PROMPT_FILE" ]] || PROMPT_FILE="$HERE/prompts/prompt-r1.md"

SID="$(uuidgen)"
OUT="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}.jsonl"
PROMPT="$(cat "$PROMPT_FILE")"
(cd "$TOY" && timeout 3600 claude -p "$PROMPT" \
    --model sonnet \
    --session-id "$SID" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

for T in 2 3 4 5; do
  A="$HERE/prompts/answer-${SCENARIO}-t${T}.md"
  [[ -f "$A" ]] || break
  OUT_T="$HERE/transcripts/${PHASE}-${SCENARIO}-rep${REP}-t${T}.jsonl"
  (cd "$TOY" && timeout 3600 claude -p --resume "$SID" "$(cat "$A")" \
      --model sonnet \
      --dangerously-skip-permissions \
      --verbose \
      --output-format stream-json > "$OUT_T" 2>&1) || true
done

echo "$TOY"
