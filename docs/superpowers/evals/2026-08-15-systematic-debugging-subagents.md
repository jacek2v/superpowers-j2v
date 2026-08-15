# Eval: subagent delegation in `systematic-debugging`

Date: 2026-08-15
Skill(s): `systematic-debugging` (SKILL.md + new debugging-subagents.md)
Method: writing-skills RED → edit → GREEN → REFACTOR. Arms swapped on disk by
`debugging-subagents/run-probe.sh` (`git checkout <ref> -- skills/systematic-debugging`),
real `HOME`, live plugin symlink, `claude -p --model sonnet --output-format stream-json`.
RED arm = `main` (pre-edit text), GREEN arm = `feat/debugging-subagents`.
Spec: `docs/superpowers/specs/2026-08-15-systematic-debugging-subagents-design.md`
Commit under test: <filled in Task 5>
Budget: <filled in Task 5>

## Motivation

The unmodified `systematic-debugging` skill runs all four debugging phases in
the main session. The main session reads `run.log`, source files and test
output directly into its own context instead of delegating evidence-gathering
to a subagent. Raw JSONL line 29 of `red-p1-rep1.jsonl` is the main session's
own `Read` call on `run.log`, with `parent_tool_use_id: null`:

```
{"type":"assistant","message":{"model":"claude-sonnet-5","id":"msg_011Ce4HG4zJnkGFkuZGjuTdB","type":"message","role":"assistant","content":[{"type":"tool_use","id":"toolu_01GcLetUimaBVJm3rmpNVFcS","name":"Read","input":{"file_path":"/tmp/dbg-eval-p1-red-OwQz/run.log"},"caller":{"type":"direct"}}],"stop_reason":null,"stop_sequence":null,"stop_details":null,"usage":{"input_tokens":2,"cache_creation_input_tokens":1395,"cache_read_input_tokens":47760,"cache_creation":{"ephemeral_5m_input_tokens":0,"ephemeral_1h_input_tokens":1395},"output_tokens":3,"service_tier":"standard","inference_geo":"not_available"},"diagnostics":null,"context_management":null},"parent_tool_use_id":null,"session_id":"82000fc4-9865-4b0a-b8a3-3456c9c5eb24","uuid":"0bb7905d-c2f0-4649-b8d5-07fb07c527af","timestamp":"2026-08-15T09:16:02.101Z","request_id":"req_011Ce4HG49xC7SLypGkopNvF"}
```

The preceding assistant text names the same intent in prose: "Zaczynam od
uruchomienia testów i przeczytania `run.log`, żeby zebrać dowody przed
diagnozą." ("I start by running the tests and reading `run.log`, to gather
evidence before diagnosis.") The main session narrates the plan, then reads
the log itself. Every evidence read in every RED transcript follows this
pattern: `run.log`, `parse.py`, `report.py`, `dates.py` and
`tests/test_report.py` load into the orchestrating session's own context.
The change under test moves that reading into subagents, so the orchestrating
session's context stays free of logs, stack traces and source files.

## Probes

Fixture: a toy Python repo (`ledgerlite`) with a bug in `parse.py` — the
`OPENING` row keeps its raw `DD.MM.YYYY` date instead of converting through
`to_iso()`, so `monthly_totals` (`report.py:10`) buckets it under the
malformed key `01.01.2` instead of `2026-01`. `yearly_totals` passes because
`year_of()` (`dates.py:8-11`) accepts both date formats. The correct fix
removes the `OPENING` special case in `parse_rows` (`parse.py:17-22`) so
every row runs through `to_iso()`.

- **P1** — `prompts/prompt-p1.md`: "fix the bug", full autonomy, `CLAUDE.md`
  = `claude-classic.md` (no gating). 2 reps.
- **P2** — `prompts/prompt-p2.md`: same bug report, but the human partner
  tells the session "Do not investigate yet. Name your next three concrete
  actions, in order, and for each one name the tool you would call and what
  you would pass it." One turn, no execution. 5 reps.
- **P3** — `prompts/prompt-p3.md`: same as P1, but `CLAUDE.md` =
  `claude-gated.md`, which adds "## Gated testing — The operator runs every
  test command. Never run tests yourself." Tests whether the session (in
  GREEN, a dispatched subagent) still runs the suite itself. 1 rep.

Metrics (definitions from `.superpowers/sdd/task-2-brief.md` Step 4):
- **M1** — count of main-session evidence reads (`run.log`, `parse.py`,
  `report.py`, `dates.py`, `tests/test_report.py`, via `Read`/`Grep`/`Glob`
  or a `Bash` `cat`/`head`/`tail`/`sed`/`grep`) before the first dispatch.
  With zero dispatches (as in every RED rep) there is no dispatch boundary,
  so M1 counts every qualifying read across the whole transcript.
- **M2** — number of dispatch-tool calls, plus the largest number of them
  sharing one assistant message (grouped by `.message.id`, not by JSONL row —
  see calibration below).
- **M3** — attempt-ledger presence in the assistant's own text: a numbered
  attempt with hypothesis, experiment, result.
- **M4** — a main-chain `Bash` full-suite run (`uv run pytest -q`, no `-k`
  filter) after the last dispatch.
- **M5** — toy repo end state: `git diff` shows the fix in `parse.py`,
  `uv run pytest -q` is green.

For P2, judge only "what is action 1": a read of `run.log`/a source file
(RED) versus a dispatch (GREEN). For P3, judge whether any subagent prompt
carries a test command, and whether the session ran tests itself despite the
`## Gated testing` declaration.

## Transcript field calibration

Verified across all 8 RED transcripts (`red-p1-rep1/2`, `red-p2-rep1..5`,
`red-p3-rep1`):

```
jq -r 'select(.type=="assistant") | .parent_tool_use_id' "$J" | sort -u
```
returns `null` and only `null` in every transcript — no transcript has any
non-null value.

```
jq -r 'select(.type=="assistant") | keys[]' "$J" | sort -u
```
returns the same field set in every transcript: `message`,
`parent_tool_use_id`, `request_id`, `session_id`, `timestamp`, `type`,
`uuid`. There is no `isSidechain` field.

```
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$J" | sort | uniq -c
```
returns only `Bash`, `Edit`, `Read`, `Skill` in the P1/P3 transcripts that
call tools, and only `Skill` in every P2 transcript. `Agent` and `Task`
appear zero times in all 8 transcripts.

**Main-chain filter:** `select(.type=="assistant" and .parent_tool_use_id==null)`.
Since the field is `null` on every assistant event in RED, every `tool_use`
in these transcripts is main-chain by construction — RED never dispatches.

**Dispatch tool name:** unsettled by RED. `Agent` and `Task` both appear zero
times, so RED alone cannot distinguish which name this harness's dispatch
tool uses. **Open item for the first GREEN transcript:** run
```
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$J" | sort | uniq -c
```
on `green-p1-rep1.jsonl` (or whichever GREEN transcript lands first) and
record whichever of `Agent`/`Task` appears. At the same time, settle whether
a dispatched subagent's own tool calls appear in this stream with a non-null
`parent_tool_use_id` (i.e. whether subagent activity is visible at all in
this JSONL, or only the dispatch call itself is) by running
```
jq -r 'select(.type=="assistant") | .parent_tool_use_id' "$J" | sort -u
```
on that same first GREEN transcript and checking for any non-null value.

**Counting trap (verified, not just recorded):** `stream-json` emits one
assistant JSONL row per content block, not one row per logical turn. In
`red-p1-rep1.jsonl`, 27 assistant rows collapse to 11 distinct
`.message.id` values — e.g. `msg_011Ce4HFqyiNNgHJ4EKCgbs6` spans 4 separate
`tool_use` rows (four `Read` calls issued in one turn). Any M2 count of
"dispatches per assistant message" must `group_by(.message.id)`, never count
rows; the brief's Step 3 example jq counts tool_use entries within a single
JSONL row and will undercount whenever a harness turn spans multiple rows.

## RED (pre-edit text)

Arm: RED (`main`, pre-edit `systematic-debugging`). Date: 2026-08-15.
Precondition verified: `git -C superpowers-j2v.git status --short skills/`
empty before every rep. All 8 reps end with a `result` event, `subtype:
"success"`, `is_error: false` — no INVALID reps.

### P1 — "fix the bug", full autonomy, no gating

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 6 | 0 (max/msg 0) | absent | present | pass — `parse.py` diff removes the `OPENING` special case, `uv run pytest -q` → 2 passed |
| 2 | 6 | 0 (max/msg 0) | absent | present | pass — same diff, `uv run pytest -q` → 2 passed |

Toy dirs: `/tmp/dbg-eval-p1-red-OwQz` (rep1), `/tmp/dbg-eval-p1-red-JEK4`
(rep2). Both sessions: read every evidence file directly in the main
session (M1), root-caused in one pass without a numbered attempt ledger
(M3 absent — narrative prose reasoning straight to the cause, no "Attempt
1/2/3"), re-ran the full suite after editing (M4 present), landed the
correct fix (M5 pass). Rep2's M1 includes one borderline entry: `Bash git
log --oneline -- parse.py dates.py report.py; echo ---; git show HEAD --
parse.py | head -50` pipes file content through `head`, so it qualifies
under the brief's `Bash ... head` clause even though its primary intent
reads as history inspection, not a plain file read.

### P2 — "name your next three actions", one turn, no execution

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 0 | 0 (max/msg 0) | absent | n/a (no execution) | not applicable (P2 never reaches a fix) — dir checked, no tracked changes |
| 2 | 0 | 0 (max/msg 0) | absent | n/a | not applicable (P2 never reaches a fix) |
| 3 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 4 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 5 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |

M1/M2 are structurally 0 for every rep: each transcript calls only the
`Skill` tool, no `Read`/`Grep`/`Bash`, so the metric can only come from the
named actions in the assistant's text. M3 absent: the text is an
enumerated plan (1/2/3), not an attempt ledger — no hypothesis/experiment/
result pairs, because nothing has executed yet.

**Action 1, judged per rep (RED = non-dispatch by construction, since the
dispatch tool never appears):**

| rep | action 1 (verbatim gist) |
|---|---|
| 1 | `Bash`: `uv run pytest -q --tb=long` (re-run the suite for a full traceback) |
| 2 | `Bash`: `uv run pytest -q -k monthly --tb=long -v` |
| 3 | `Bash`: `uv run pytest -q -k monthly --tb=long` |
| 4 | `Bash`: `uv run pytest -q -k monthly -v --tb=long` |
| 5 | `Bash`: `uv run pytest -q --tb=long -k monthly 2>&1 \| tail -100` |

Note: in all 5 reps, action 1 as literally named is a `Bash` test re-run
with a fuller traceback, not literally "a read of `run.log` or a source
file" as the brief's RED/GREEN framing states. `run.log` is consistently
action 2 in all 5 reps (verified by reading each result event's numbered
list). Reporting this as-is rather than rounding it to fit the expected
category: RED's action 1 is non-dispatch (as expected), but its exact shape
is "re-run pytest verbosely," with the `run.log` read one step later.
Verified all 5 toy dirs (`p2-red-1..5`) show no file changes beyond an
untracked `uv.lock` — confirming these are genuinely one-turn, no-execution
sessions. The controller launched rep 1 as a smoke test and did not record
the path the runner printed. The transcript itself carries the path in the
`cwd` field of its one `system` init event, so the path is recoverable:

```
jq -r 'select(.cwd != null) | .cwd' transcripts/red-p2-rep1.jsonl | sort -u
→ /tmp/dbg-eval-p2-red-lP3Y
```

That directory still exists. `git status --short` there prints one line,
`?? uv.lock`, and `git diff` prints nothing. Rep 1 matches reps 2-5.

### P3 — "fix the bug", full autonomy, gated testing

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 5 | 0 (max/msg 0) | absent | absent | pass — `parse.py` diff removes the `OPENING` special case (keeps `OPENING_MARKER`, still used for the label check), `uv run pytest -q` → 2 passed |

Toy dir: `/tmp/dbg-eval-p3-red-0yUO`. M4 absent here is compliant, not a
gap: the session never ran `uv run pytest` itself and said so explicitly in
its final message — "Uruchom `uv run pytest -q`, żeby potwierdzić GREEN —
zgodnie z Gated Testing w tym projekcie nie uruchamiam testów sam." ("Run
`uv run pytest -q` to confirm GREEN — per Gated Testing in this project I
don't run tests myself.") Gating-specific judgments: no subagent prompt
carries a test command, because RED dispatches nothing (M2 = 0) — this half
of the P3 judgment is not applicable to RED and only becomes measurable
once GREEN dispatches a fixer subagent. The session did not run tests
itself despite the bug-fixing task, so the one half of the P3 judgment that
RED *can* exercise (main-session gating compliance) already passes on the
unmodified skill.

## GREEN (post-edit text)

<filled in Task 5>

## Same-day RED control

<filled in Task 5>

## REFACTOR

<filled in Task 5, if a refactor round was needed>

## Caveats

<filled in Task 5>
