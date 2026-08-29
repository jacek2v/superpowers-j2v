#!/usr/bin/env bash
# Prints the evidence for the three gated-dispatch pass criteria from one
# Claude Code session transcript. The verdict stays with the reader.
set -euo pipefail

transcript="${1:?usage: judge-transcript.sh <session.jsonl>}"

# One TSV line per tool call, in call order: name, subagent type, first payload field.
tool_calls() {
    jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
           | [ .name,
               (.input.subagent_type // "-"),
               ((.input.file_path // .input.command // .input.pattern // "-") | tostring | gsub("\n"; " ")) ]
           | @tsv' "$transcript"
}

echo "== C1: how the round output was read =="
tool_calls | grep -n "round1.out" || echo "(no tool call names round1.out)"

echo
echo "== C2: ledger write and dispatch, in call order =="
tool_calls | grep -n -E "rounds\.md|^Agent" || echo "(neither a ledger write nor a dispatch)"

echo
echo "== C3: dispatch target, and code the session wrote itself =="
tool_calls | awk -F'\t' '$1=="Agent" { print "dispatch: " $2 }'
tool_calls | awk -F'\t' '$1=="Edit" || $1=="Write" || $1=="NotebookEdit" { print "tool write: " $3 }'
# A session can write code through Bash instead of Edit/Write, so scan Bash
# commands that touch the code worktree for a write construct.
tool_calls | awk -F'\t' '$1=="Bash" { print $3 }' \
    | grep -E "ggi-probe" \
    | grep -E "git (add|commit)|sed -i|tee |open\([^)]*, *.w.|>>? *'?\"?[^ ]*\.(sql|ps1|py|md|json|yml)" \
    | cut -c1-140 \
    | sed 's/^/bash write: /' || true
