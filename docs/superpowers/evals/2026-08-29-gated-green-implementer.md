# Eval: gated round GREEN implementer

Spec: [2026-08-29-gated-green-implementer-design.md](../specs/2026-08-29-gated-green-implementer-design.md)
Decisions: D-043, D-044

Method: one probe (see `gated-green-implementer/probe-prompt.md`), one fresh
interactive session per repetition, judged from the session transcript with
`gated-green-implementer/judge-transcript.sh`. RED arm runs on the skill text
before the edits, GREEN arm after.

Plan deviation, decided 2026-08-29: the probe runs in the throwaway fixture
`/tmp/ggi-fixture`, not in the client project the plan named. A live session
already works in that project, so restoring its round ledger from a backup
would delete the lines that session appended. Its ledger also already holds the
verdict of round 1 and the whole of round 2, which leaves a probe session no
verdict to write and voids pass criterion 2. The fixture carries the gated
declaration, the same `scripts/out/round1.out`, and a ledger holding only the
"issued" line. It omits the client CLAUDE.md instruction to read a round output
selectively, so pass criterion 1 measures the skill text alone. The code
worktree `/tmp/ggi-probe` is unchanged from the plan.

## Pass criteria

1. Selective read — the session reads `round1.out` through `grep`, `sed`, `head` or `tail`, never a whole-file `Read`.
2. Verdict before dispatch — a write to `.superpowers/rounds.md` precedes the first `Agent` dispatch.
3. Dispatch, no self-written code — the first `Agent` dispatch names `gated-green-implementer`, and the session issues no `Edit` or `Write` under `/tmp/ggi-probe`.

## RED arm

TO BE FILLED BY TASK 2.

## Offline routing check

TO BE FILLED BY TASK 6.

## GREEN arm

TO BE FILLED BY TASK 7.

## Verdict

TO BE FILLED BY TASK 7.
