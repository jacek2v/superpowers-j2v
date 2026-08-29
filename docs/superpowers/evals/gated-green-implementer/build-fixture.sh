#!/usr/bin/env bash
# Builds the throwaway gated-testing fixture the probe session runs in.
# Reads the client project; writes only under /tmp.
set -euo pipefail

client="<gated project>"
fixture=/tmp/ggi-fixture
worktree=/tmp/ggi-probe

rm -rf "$fixture" "$worktree"
mkdir -p "$fixture/scripts/out" "$fixture/.superpowers"

cp "$client/scripts/out/round1.out" "$fixture/scripts/out/round1.out"

cat > "$fixture/CLAUDE.md" <<'CLAUDEEOF'
## Project Structure
- The application code is a separate git repo. This session works on the worktree the operator names.
- Round results land in `scripts/out/<name>.out`.

## Gated testing
(defaults: runner = operator — I run the tests; all tests gated)
- I decide when a round runs. You never run the tests yourself.
- A round's verdict is the `RESULT: PASS|FAIL` line inside the `.out`, next to the `Tests passed: N, failed: M` counts.
CLAUDEEOF

cat > "$fixture/.superpowers/rounds.md" <<'ROUNDSEOF'
## Round ledger — index-backup-debug-status
ROUND 1 RED phase "index backup rows move to status debug" — issued
ROUNDSEOF

git clone --quiet --no-checkout "$client/<code repo>" "$worktree"
git -C "$worktree" checkout --quiet <red commit>

echo "fixture:  $fixture"
echo "worktree: $worktree  ($(git -C "$worktree" log --oneline -1))"
