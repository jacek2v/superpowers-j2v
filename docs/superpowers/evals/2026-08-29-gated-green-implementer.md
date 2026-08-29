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

Date: 2026-08-29. Skill text: `main`, before the edits. One repetition,
transcript `gated-green-implementer/transcripts/red-rep1.jsonl`. Tool calls are
cited by their index in the transcript's call order.

| Criterion | Result | Evidence |
|---|---|---|
| 1 — selective read | FAIL | Call 1 read the whole file: `cat scripts/out/round1.out`. No `grep`, `sed`, `head` or `tail` on it anywhere. |
| 2 — verdict before dispatch | FAIL | The ledger write is call 24, after the code commit at call 17. No dispatch happened at all, so the ordering the criterion protects was never exercised. |
| 3 — dispatch, no self-written code | FAIL | Zero `Agent` calls. Call 16 rewrote `the procedure file` through a `python3` heredoc, call 17 committed it as `<commit>`. |

RED verdict: the session judged the round correctly, then wrote and committed
the GREEN change itself and asked for a deployment plus round 2 — the defect the
spec's Problem section names.

Judge correction, same day: the session wrote the code through `Bash`, not
through `Edit` or `Write`, so the first version of `judge-transcript.sh` printed
an empty C3 block and criterion 3 read as a false pass. The C3 block now also
scans `Bash` commands that touch the code worktree for a write construct.

## Offline routing check

TO BE FILLED BY TASK 6.

## GREEN arm

TO BE FILLED BY TASK 7.

## Verdict

TO BE FILLED BY TASK 7.
