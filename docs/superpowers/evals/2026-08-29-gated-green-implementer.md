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
scans `Bash` commands for a write construct.

Second judge correction, after the branch review: the C3 block first required
the worktree path in the same `Bash` command as the write construct. The Bash
tool keeps its working directory between calls, so a session could `cd` into
the worktree in one call and write in the next without naming the path. The
filter now scans every `Bash` call and excludes only the ledger append, which
is criterion 2's evidence. Re-running it over all six transcripts returned the
same verdicts and no false positive.

## Offline routing check

Three real round outputs from `<gated project>/scripts/out/`, read selectively
and routed by the SKILL.md table. Command used, one per file:

    grep -nE "^\[FAIL\]|Tests passed|^RESULT" <file>

| File | Lines in file | Lines the grep returned | Verdict | Target |
|---|---|---|---|---|
| `round1.out` | 10 | 3 | Valid RED — assertion failure on the missing debug row | `gated-green-implementer` |
| `obj_red5.out` | 44 | 7 | INVALID RED — `Error occurred in Describe block`, `Cannot bind argument to parameter 'Path' because it is null` | `sdd-rescue` |
| `cat_green1.out` | 319 | 22 | Gate GREEN failure — full suite, 1464 passed, 20 failed, `RESULT: FAIL` | `sdd-rescue` |

Selective reading stayed sufficient on all three, including the 319-line output,
where the grep returned 22 lines.

Spec correction: the spec named `round1b.out` and described it as 1766 lines.
It is 1766 bytes, 6 lines, `RESULT: PASS` — it fits neither goal of this check,
so the three files above replace it.

Plan correction: the plan calls `round1.out` a 13-line file. It is 10 lines.

## GREEN arm, first pass — discarded

Date: 2026-08-29. Skill text: commit `702929f`. Transcripts
`gated-green-implementer/transcripts/green-rep1.jsonl` and `green-rep2.jsonl`.

Repetition 1 dispatched `gated-green-implementer` after writing the verdict.
Repetition 2 wrote the change itself and committed `aaaf602`, with zero `Agent`
calls, and said so in its own words: the skill tells it to hand the code to
`gated-green-implementer`, but it also holds an instruction not to call an
agent unless asked.

That instruction is not the operator's. It reaches every session on this
machine from an Anthropic client-side experiment, cached in `~/.claude.json`
under `clientDataCacheSlots.*.data` with
`experimentKey = claude_code_opus5_efficiency_paragraph_experiment`. Its text:
"Do not call the AgentTool unless the user requested it". It sits in the same
paragraph as guidance about turn cost, so a gate dispatch reads as an
unrequested subagent.

The skill loaded in repetition 2, the routing subsection was in context, and
the agent name appears in the transcript four times — the session read the
routing and overrode it. So this is a real failure of the skill text, not an
invalid repetition.

Fix, commit `2de3195`: one sentence in "Who Writes the Change" naming the gate
dispatch as work the human partner already asked for. It targets the
misreading directly and does not depend on the operator changing global
configuration, which matters because the experiment payload can change without
notice.

## GREEN arm

Date: 2026-08-29. Skill text: commit `2de3195`, after the fix. Three fresh
repetitions, transcripts `green-b-rep1.jsonl` through `green-b-rep3.jsonl`.
Tool calls are cited by their index in the transcript's call order.

| Rep | 1 — selective read | 2 — verdict before dispatch | 3 — dispatch, no self-written code |
|---|---|---|---|
| 1 | FAIL in substance | PASS — ledger 17, dispatch 18 | PASS — `gated-green-implementer`, no session write |
| 2 | FAIL in substance | PASS — ledger 17, dispatch 18 | PASS — `gated-green-implementer`, no session write |
| 3 | FAIL | PASS — ledger 14, dispatch 15 | PASS — `gated-green-implementer`, no session write |

Criterion 1 needs its own explanation. Repetitions 1 and 2 piped `cat` into
`head -100` and `head -80`, which passes the criterion's letter, because `head`
is one of the named commands. Repetition 3 ran a bare `cat`. On a 10-line file
every one of those forms reads the whole thing, so no repetition read
selectively in substance. The criterion cannot discriminate on this fixture. A
fixture with a 319-line output — `cat_green1.out`, already used in the offline
routing check — would measure it. That measurement is not in this eval.

Subagent diff versus the reference commit `<reference commit>`, which changed one file
with 2 insertions and 1 deletion:

| Rep | Commit | Files | Diff |
|---|---|---|---|
| 1 | `00b7aeb` | `the procedure file` | 1 insertion, 1 deletion |
| 2 | `7350e93` | `the procedure file` | 1 insertion, 1 deletion |
| 3 | `e6f8047` | `the procedure file` | 1 insertion, 1 deletion |

All three touched the reference file and no other. Each is one line shorter
than the reference, which added a why-comment the subagents did not write. The
pass criteria measure the session, not the subagent, so this is a concern on
the record, not a failure.

## Verdict

Criteria 2 and 3 — the ones the feature exists for — are 3/3 after the fix, against
0/3 in the RED baseline. D-043 and D-044 are implemented and measured.

Criterion 1 is 0/3 in substance and is not evidence for anything: the 10-line
fixture cannot separate a selective read from a full one. The skill text asking
for a selective read ships unmeasured.

The first GREEN pass also produced a finding worth more than the pass itself: a
client-side efficiency experiment can override this skill's routing, and the
skill needs one sentence to survive it. Removing that sentence reopens the
failure.
