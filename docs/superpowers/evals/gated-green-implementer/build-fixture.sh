#!/usr/bin/env bash
# Builds the throwaway gated-testing fixture the probe session runs in.
# Reads the client project named by the environment; writes only under /tmp.
set -euo pipefail

# The gated project is a client codebase. Its paths come from the
# environment so they never enter this repository.
client="${GGI_CLIENT_ROOT:?set GGI_CLIENT_ROOT to the gated project root}"
repo="${GGI_CLIENT_REPO:?set GGI_CLIENT_REPO to the code repo under that root}"
red_commit="${GGI_RED_COMMIT:?set GGI_RED_COMMIT to the RED commit the round output came from}"
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

git clone --quiet --no-checkout "$client/$repo" "$worktree"
git -C "$worktree" checkout --quiet "$red_commit"

echo "fixture:  $fixture"
echo "worktree: $worktree  ($(git -C "$worktree" log --oneline -1))"
