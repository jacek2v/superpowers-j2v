# Eval: subagent delegation in `systematic-debugging`

Date: 2026-08-15
Skill(s): `systematic-debugging` (SKILL.md + new debugging-subagents.md)
Method: writing-skills RED → edit → GREEN → REFACTOR. Arms swapped on disk by
`debugging-subagents/run-probe.sh` (`git checkout <ref> -- skills/systematic-debugging`),
real `HOME`, live plugin symlink, `claude -p --model sonnet --output-format stream-json`.
RED arm = `main` (pre-edit text), GREEN arm = `feat/debugging-subagents`.
Spec: `docs/superpowers/specs/2026-08-15-systematic-debugging-subagents-design.md`
Commit under test: `7c9a5ee0e5c954d56ed99c9d5bc7bac88cbb9023` — "docs(systematic-debugging): tie the fix counter to the failure ladder" (HEAD of `feat/debugging-subagents` at Task 5 time; includes both the eight planned insertions and the ninth, additive one — see Caveats).
Budget: not defined by any task brief or the design spec — left unfilled rather than invented.

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

**Dispatch tool name — SETTLED on `green-p1-rep1.jsonl`:**
```
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$J" | sort | uniq -c
```
returns `5 Agent`, `17 Bash`, `3 Edit`, `3 ListAgents`, `16 Read`,
`1 ScheduleWakeup`, `1 Skill`. **The dispatch tool is `Agent`.** `Task` does
not appear.

**Subagent visibility — SETTLED on `green-p1-rep1.jsonl`:**
```
jq -r 'select(.type=="assistant") | .parent_tool_use_id' "$J" | sort -u
```
returns `null` plus five distinct non-null tool_use ids (one per `Agent`
dispatch in that transcript). **Subagent tool calls DO appear in this
stream**, each carrying `parent_tool_use_id` equal to the dispatching
`Agent` call's `tool_use.id`.
```
jq -r 'select(.type=="assistant") | .parent_tool_use_id' "$J" | grep -v '^null$' | wc -l
```
returns `51` — 51 subagent-side assistant events in this one transcript.
**Main-chain filter for GREEN:** `select(.type=="assistant" and .parent_tool_use_id==null)`.
Every metric about the main session below applies this filter; an
unfiltered tool inventory mixes subagent reads into the main session's
count and would make M1 look catastrophic when it is zero.

**Counting-trap re-verification, on `green-p1-rep1.jsonl`:**
```
jq -r 'select(.type=="assistant" and .parent_tool_use_id==null)
       | .message.id as $m
       | .message.content[]? | select(.type=="tool_use" and .name=="Agent")
       | [$m, .id, (.input.description // "")] | @tsv' "$J" \
  | awk -F'\t' '{c[$1]++; print} END{for (k in c) print k, c[k]}'
```
confirms the brief's own worked example: three investigators
(`msg_011Ce4MbbPQCtYBGgAmEaTXg`, count 3 — "read errors and run.log",
"recent changes and repro determinism", "trace bad value backward"), then
an experimenter alone (`msg_011Ce4MgKQN89HqjGRQWVng8`, count 1), then a
fixer alone (`msg_011Ce4MkapvFYU6hY3zywquJ`, count 1). Grouping by
`.message.id` and summing blocks — never counting rows, never deduping rows
before summing — reproduces this correctly.

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

Arm: GREEN (`feat/debugging-subagents`, commit `7c9a5ee0`). Date: 2026-08-15.
Precondition verified: working tree on the feature arm before every rep
(runner restores it via the patched EXIT trap — see Caveats). All 9 reps end
with a `result` event, `subtype: "success"` — no INVALID reps.

### P1 — "fix the bug", full autonomy, no gating

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 0 | 5 (max/msg 3) | present | present | pass — `parse.py` diff, `uv run pytest -q` → 2 passed |
| 2 | 0 | 5 (max/msg 3) | present | present | pass — `parse.py` diff (removes `OPENING_MARKER` special case entirely), `uv run pytest -q` → 2 passed |

Toy dirs: `/tmp/dbg-eval-p1-green-97mP` (rep1), `/tmp/dbg-eval-p1-green-1u9u`
(rep2). Both reps: first dispatch message carries exactly 3 investigators
(target 2-4, met), zero evidence-file reads before that dispatch (target 0,
met), a numbered `Attempt 1` ledger entry before the fixer dispatch (target
met — quotes below), a main-chain `uv run pytest -q` after the fixer
returns (target met), and the correct fix landed with the suite green
(target met).

Rep1's M1 has one borderline call not counted, flagged here because it is
stronger than rep2's and this rep is the flagship quote source below: `Bash
uv run pytest -q 2>&1 | tail -60`, issued at 10:12:47Z, before the first
`Agent` dispatch at 10:13:00Z. It pulls the assertion diff and the file
references from the failing test straight into the main session's own
context. M1 scores it 0 and that score stands: M1 counts reads of five
enumerated evidence files (`run.log`, `parse.py`, `report.py`, `dates.py`,
`tests/test_report.py`), and this is live command output, not one of those
files. The `tail` here truncates a pipe from `pytest`, it does not read a
file. Recorded rather than passed over, so the 0 is not read as "the main
session saw no failure detail before dispatching," which it did.

Rep2's M1 has one borderline call not counted: `Bash wc -l dates.py parse.py
report.py tests/test_report.py run.log pyproject.toml`, issued before the
first dispatch. It names all five evidence files as arguments, but the verb
is `wc`, which M1's definition does not enumerate (`cat`/`head`/`tail`/
`sed`/`grep` only) — `wc -l` returns line counts, not file content, so
nothing is read into the main session's context. Scored 0, flagged rather
than silently ignored, the same way RED's calibration flagged its own
`git show | head` borderline case.

**Verbatim dispatch message** (one of three investigators in
`green-p1-rep1.jsonl`'s first dispatch, `msg_011Ce4MbbPQCtYBGgAmEaTXg`,
tool_use `toolu_01X3qBBFhfXYfocGL9Ehyfcv`):

> "You are a read-only debugging investigator. Investigate ONE path and
> report what the evidence shows. You are not fixing anything and you are
> not deciding anything. [...] Your path: read the error output and the
> stack trace end to end. Also read run.log end to end [...] Read dates.py,
> parse.py, report.py, and tests/test_report.py in full and quote the exact
> lines involved in producing the key "01.01.2" and the value -80.5 vs
> 1119.5. [...] Rules: - Do NOT edit source files. Do NOT commit. Do NOT
> propose a fix. - Quote evidence. Never paraphrase an error message."

**Verbatim ledger entry** (`green-p1-rep1.jsonl`, main-chain text, before
the experimenter dispatch):

> "Attempt 1 — hipoteza: parse.py:20-22 pomija to_iso() dla wiersza OPENING,
> więc entry.date zostaje w DD.MM.YYYY zamiast ISO. monthly_totals
> (report.py:10) zakłada zawsze ISO przez entry.date[:7], stąd błędny klucz
> "01.01.2" i błędna suma dla 2026-01. yearly_totals działa, bo year_of()
> (dates.py:8-11) toleruje oba formaty. eksperyment: w parse.py:21 zamienić
> Entry(raw_date, ...) na Entry(to_iso(raw_date), ...) i uruchomić `uv run
> pytest -q`."

**A finding M1 does not capture, reported because it bears on the feature's
actual goal, not because any defined metric requires it:** in `green-p1-
rep2.jsonl`, after the experimenter confirms the hypothesis, the main
session's own text says "Zanim wyślę fixera, odczytam pełny kod plików,
żeby dokładnie sformułować zakres poprawki" ("Before I send the fixer, I'll
read the full code myself, to scope the fix precisely") and then the main
chain does 4 `Read` calls (`parse.py`, `dates.py`, `report.py`,
`tests/test_report.py`) plus a `grep`, directly in the orchestrating
session. M1 only counts reads *before the first dispatch*, so this scores
0 by the metric as defined — but it is the exact behavior the change exists
to remove (Motivation, above), reappearing between the experimenter and the
fixer dispatch instead of before the first one. The same pattern recurs in
P3 rep2 (below). Two of four P1/P3 GREEN reps show it.

### P2 — "name your next three actions", one turn, no execution

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 2 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 3 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 4 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 5 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |

Every rep's main chain calls only `Skill` (loading `debugging-subagents.md`)
and, in reps 1/4/5, one incidental `Read`/`Bash cat`/`Bash find` of that
same reference file — never a dispatch, because P2 is a naming exercise,
not execution. M2 is structurally 0 for the same reason it was 0 in RED:
nothing is dispatched in a one-turn plan. M3 absent is expected: an
enumerated 1/2/3 plan is not an attempt ledger.

**Action 1, judged per rep — this is the metric the GREEN target table
actually asks for on P2:**

| rep | action 1 (verbatim gist) |
|---|---|
| 1 | `Agent` × 3 in one message, `subagent_type: Explore` — investigators for paths 1, 4, 5 |
| 2 | **`Read`** of `debugging-subagents.md` — the dispatches are items 2 and 3: `Agent` × 2 in one message + a third `Agent` alone, `subagent_type: Explore` — paths 1, 4, then 5 |
| 3 | `Agent` × 2 in one message, `subagent_type: Explore` — paths 1 and 4; step 3 is the session's own synthesis, no tool |
| 4 | `Agent` × 3 in one message, `subagent_type: Explore` — investigators for 3 named paths |
| 5 | `Agent` × 3 in one message, `subagent_type: Explore` — investigators for 3 named paths |

Four of 5 reps: action 1 as named is a dispatch, not a read. **P2 target met
4/5.** Rep 2 misses the literal target: its own numbered list opens with a
`Read` of `debugging-subagents.md`, and its two dispatches are items 2 and 3.
Verbatim, item 1 of rep 2's list: "**Read** → plik `debugging-subagents.md` w
katalogu skilla `systematic-debugging`. Muszę poznać szablony promptów i
format zwrotki, zanim wyślę subagentów." ("**Read** → the file
`debugging-subagents.md` in the `systematic-debugging` skill directory. I must
learn the prompt templates and the return format before I send the
subagents.") Both facts are recorded, neither is hidden: the literal target is
missed in that rep, and the read that misses it is the skill's own reference
file, which the skill requires the session to load before any dispatch. It is
not an evidence read of `run.log` or a source file, so it is not the behavior
the probe tests for. The other 4 reps open with `Agent` (verified in each
rep's own numbered list). The RED comparison is unaffected — RED never
dispatched at all, in any rep. Compare against the RED shape actually
observed, not the plan's
idealized framing: RED's action 1 in all 8 RED reps (5 original + 3
same-day control, below) was `uv run pytest -q --tb=long` or a `-k`-filtered
variant of it — a fuller-traceback test re-run — never literally "a read of
`run.log`/a source file" as the design doc's RED/GREEN framing states, and
never a dispatch. The GREEN-versus-RED contrast on P2 is therefore
dispatch-vs-pytest-rerun, not dispatch-vs-file-read; both arms are reported
as measured, not rounded to the plan's description.

Toy dirs `/tmp/dbg-eval-p2-green-{U0ah,fZMK,E7N6,RlMt,d781}` all show no
tracked changes beyond an untracked `uv.lock` — confirming these are
genuinely one-turn, no-execution sessions, same as RED.

### P3 — "fix the bug", full autonomy, gated testing

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 1 | 0 | 6 (max/msg 3) | present | absent (compliant) | pass — `parse.py` diff, `uv run pytest -q` → 2 passed, fix left uncommitted |
| 2 | 0 | 6 (max/msg 3) | present | absent (compliant) | pass — `parse.py` diff, `uv run pytest -q` → 2 passed, fix committed `d2f96db` |

Toy dirs: `/tmp/dbg-eval-p3-green-7vjK` (rep1), `/tmp/dbg-eval-p3-green-uJ3H`
(rep2). M4 "absent" is scored compliant for both reps, on the same logic
RED's own P3 row used: under `## Gated testing`, the main session must not
run the suite itself either, so an absent main-chain `pytest` run after the
fixer is the correct behavior, not a gap. Rep1's fixer left the fix
uncommitted, citing the global CLAUDE.md rule against committing without an
explicit request — `git log` in that toy dir still shows only the initial
commit; `git diff` shows the one-line fix. Rep2's fixer committed
(`d2f96db`), consistent with its own dispatch brief's step 5 ("Commit the
fix... together").

**P3 gating-specific judgment — no test command in any subagent prompt, and
a `ROUND` request in the main session (target 2/2):**

| rep | subagent prompt carries a test command | `ROUND`-formatted request in main session |
|---|---|---|
| 1 | No — every prompt says "Do NOT run pytest or uv run pytest"; the experimenter gets a `uv run python -c "..."` diagnostic script instead | No — the main session's own close is an informal "Uruchom `uv run pytest -q` i wklej wynik" ("Run `uv run pytest -q` and paste the result"), not the `ROUND <n> — RED\|GREEN` template from `test-driven-development/SKILL.md` |
| 2 | **Yes** — the first investigator's prompt says "Run `uv run pytest -q` yourself in /tmp/dbg-eval-p3-green-uJ3H and read the full output carefully" (verbatim, tool_use `toolu_01PfoWgKiUBDctGyDLeN26yX`), and the dispatched subagent's own tool calls (filtered on `parent_tool_use_id == "toolu_01PfoWgKiUBDctGyDLeN26yX"`) show it ran pytest three times: `uv run pytest -q 2>&1`, `uv run pytest -q -vv 2>&1`, `uv run pytest -vv 2>&1` | Yes — "**ROUND 1 — GREEN**\n\nUruchom:\n```\nuv run pytest -q\n```\n\nPaste back: pełne wyjście polecenia." — matches the `ROUND <n> — RED\|GREEN` and `Paste back:` shape from `test-driven-development/SKILL.md` |

**Neither rep satisfies both halves of the compound P3 target. 0/2, not
5/5 or 2/2 rounded down — reported as measured.** Rep1 gets the
no-test-command half right but never produces the templated round request.
Rep2 produces the templated round request but its first investigator both
carries and executes a test command, in a probe whose whole point is
verifying the gate holds. See "Targets missed" below.

## Same-day RED control

Arm: RED (`main`, pre-edit `systematic-debugging`), re-run on the SAME day
as the GREEN reps above so the comparison is not against a stale baseline.
Date: 2026-08-15. Precondition verified: `git status --short skills/` empty
before every rep. All 4 reps end with a `result` event, `subtype:
"success"` — no INVALID reps. Calibration re-checked on every control
transcript: `Agent`/`Task` both appear 0 times, `parent_tool_use_id` is
`null` on every assistant event — RED still dispatches nothing, so every
`tool_use` is main-chain by construction, same as the original 8 RED reps.

### P1 — rep 3

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 3 | 6 | 0 (max/msg 0) | absent | present | pass — `parse.py` diff removes the `OPENING` special case, `uv run pytest -q` → 2 passed |

Toy dir: `/tmp/dbg-eval-p1-red-dRRk`. Same shape as `red-p1-rep1/2`: 4
`Read` calls on `dates.py`/`parse.py`/`report.py`/`run.log`, a `Bash find
tests -type f | xargs cat` reading `tests/test_report.py` (+1), and a `git
log ... && git show HEAD -- parse.py | head -50` (+1, same borderline
`Bash ... head` case the original RED calibration flagged) — M1 = 6,
matching `red-p1-rep1`'s M1 = 6 exactly. Root-caused in one narrative pass,
no numbered ledger (M3 absent), re-ran the full suite after editing (M4
present), correct fix landed (M5 pass).

### P2 — reps 6, 7, 8

| rep | M1 | M2 | M3 | M4 | M5 |
|---|---|---|---|---|---|
| 6 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 7 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |
| 8 | 0 | 0 (max/msg 0) | absent | n/a | not applicable |

Each transcript calls only `Skill`, no `Read`/`Grep`/`Bash` — same as the
original 5 RED reps, M1/M2 structurally 0.

**Action 1, judged per rep:**

| rep | action 1 (verbatim gist) |
|---|---|
| 6 | `Bash`: `uv run pytest -q --tb=long -k monthly` |
| 7 | `Bash`: `uv run pytest -q -k monthly --tb=long` |
| 8 | `Bash`: `uv run pytest -q -k monthly -v` |

Same shape as `red-p2-rep1..5`: action 1 is a `Bash` full-traceback test
re-run, never a dispatch, `run.log` is action 2 in every rep. Toy dirs
`/tmp/dbg-eval-p2-red-{85Eq,HJlf,MNpQ}` all show `git diff` empty and
`uv run pytest -q` still red (`1 failed, 1 passed`) — confirming genuine
one-turn, no-execution sessions with the bug still present.

**Control conclusion:** the same-day RED control reproduces the Task 2 RED
shape exactly — M1 ≥ 1 with the same borderline pattern, M2 = 0 in every
rep, P2 action 1 a pytest re-run in every rep. Nothing about re-running the
old text on 2026-08-15 differs from the original RED baseline recorded
2026-08-15 earlier the same day. The GREEN-versus-RED difference reported
above (M1 0 vs 6, M2 0 vs 5-6, M3 absent vs present, P2 action 1 pytest-
rerun vs dispatch) is therefore evidence, not noise from an aged baseline.

## REFACTOR

**Not run.** The plan's Step 4 refactor loop (classify → edit
`skills/systematic-debugging/{SKILL.md,debugging-subagents.md}` → commit →
re-run the failed probe → record) is superseded for this task by an
explicit controller instruction: classify the miss, then STOP and report to
the controller instead of editing the skill. Editing skill text is reserved
as a controller decision, because the whole measurement depends on the
arm's text being what this eval doc says it is. No skill file was touched
in this task.

**Target missed:** the compound P3 target ("no test command in any subagent
prompt; a `ROUND` request appears in the main session", target 2/2) — actual
0/2. Two distinct failures, one per rep, not one failure seen twice:

1. **Rep2 — a subagent ran (and was told to run) the suite in a gated
   probe.** This matches Step 4's fourth listed category almost exactly:
   "A subagent ran the suite in P3 → the gated section is too far from the
   fixer brief; add the constraint to the fixer dispatch line itself." One
   deviation from that category as written: the violation is not in the
   *fixer's* brief, it is in the *first investigator's* brief — `debugging-
   subagents.md`'s "Gated Testing Projects" section states the fixer's
   change explicitly ("loses steps 2 and 4 of its template... say so in its
   brief") but only says investigators "work unchanged — they read, they do
   not run tests" without an explicit "do not run pytest" instruction
   placed at the investigator dispatch site itself. Rep1's investigators
   got that instruction anyway (each prompt says "Do NOT run pytest or uv
   run pytest" explicitly); rep2's first investigator did not. The proposed
   fix by Step 4's own logic would be: make the "no test command" rule
   explicit at *every* Phase 1-4 dispatch template in `debugging-
   subagents.md` under gating, not only the fixer's — the current text
   states the rule once in prose above the four bullets and trusts each
   dispatch to inherit it.

2. **Rep1 — no `ROUND`-formatted request ever appears.** This does not
   match any of Step 4's four listed miss categories (file-read-before-
   dispatch, single investigator, no ledger, subagent-ran-suite). It is a
   fifth shape: `debugging-subagents.md`'s "Gated Testing Projects" section
   says the rounds are "yours" to request but never shows the literal
   `ROUND <n> — RED\|GREEN` / `Paste back:` template inline — that template
   lives only in `test-driven-development/SKILL.md`, a different skill file
   this task is not permitted to edit either. Rep1 improvised a plain-
   language request instead of loading and using the cross-referenced
   template; rep2 happened to load it. Per Step 4's own closing rule ("a
   third miss on the same target is a finding for your human partner, not a
   third guess"), a miss shape absent from the provided classification
   table is treated the same way here: reported, not guessed at.

No re-run was attempted for either half, since no edit was made.

## Caveats

**From the brief's Step 5, minimum required:**
- All 21 reps (13 in this task plus the 8 original RED reps) ran on
  `--model sonnet`. The debugging orchestrator runs on opus in real
  sessions — none of these results verify opus-level compliance with the
  dispatch discipline.
- No probe exercises a multi-component system. `ledgerlite` has one
  boundary (`parse.py` → `report.py`), so Phase 1 path 4 (component-
  boundary evidence) is never the path that actually decides the root
  cause — it is dispatched in every P1/P3 rep but its findings duplicate
  what path 1 or path 5 already established.
- No probe forces the Failure Ladder. No fixer failed even once across all
  13 reps, so the `sdd-rescue` rung (2nd failure) and the STOP rung (3rd
  failure) are completely unmeasured — including the ninth SKILL.md
  insertion that resolves the ladder/Phase-4-item-4 conflict (see below).
- The P3 gated probe measures one turn, not a full gated-TDD round cycle.
  Neither rep's session receives the operator's pasted `pytest` output and
  continues past it — both end their turn requesting or half-requesting the
  round. Whether the session correctly resumes after a real RED/GREEN
  round is unmeasured.

**Two deviations from the plan that materially affect how to read every
number above:**

1. **The runner was patched before any rep ran.** The plan's verbatim
   `run-probe.sh` had two defects a review caught before Task 5 started:
   `set -euo pipefail` combined with nine unguarded commands between the
   arm swap and the restore, so any failure in that window left the live
   plugin on the wrong arm for every subsequent rep; and `git checkout
   <ref> -- <dir>` is a one-way overlay that never deletes files absent
   from the target ref, so a `red` swap performed after `debugging-
   subagents.md` existed on the feature branch would have left that
   reference file on disk during a nominally-RED rep, silently feeding
   GREEN prompt templates into a RED-arm session. The human partner
   approved fixing both: an `EXIT` trap restoring the feature arm,
   installed after the dirty-skill precondition check, plus a `swap_to`
   helper that does `rm -rf` then `git checkout` in both directions. Every
   rep in this eval — all 8 original RED reps, all 9 GREEN reps, and all 4
   same-day RED control reps — ran against this patched runner, never the
   plan's original one. Step 7's working-tree check (below) is the runtime
   evidence that the trap held across all 13 of this task's reps.

2. **A ninth insertion landed in `SKILL.md`, beyond the eight the plan
   lists.** A review found that the plan's new Failure Ladder (`## The
   Failure Ladder` in `debugging-subagents.md`, reproduced above) contradicts
   the preserved pre-existing Phase 4 item 4 in `SKILL.md` ("If < 3: Return
   to Phase 1, re-analyze with new information") — the two attempt-counting
   rules disagreed about when three failures triggers architecture
   questioning versus a return to Phase 1. The human partner approved a
   purely additive resolving sentence after item 4: "**The failure ladder
   above governs this count.** A failed fixer dispatch is one attempt on
   that ladder. Return to Phase 1 only when the ladder sends you there."
   Item 4 itself stays byte-identical; nothing was deleted or reworded. No
   probe in this eval forces the Failure Ladder (see above), so this
   resolving sentence ships unmeasured — its correctness rests on the
   review that caught the contradiction, not on eval evidence.

**From this task's own measurement, not anticipated by the brief:**

- M1's definition ("before the first dispatch") does not cover reads that
  happen *between* dispatches. Two of four P1/P3 GREEN reps
  (`green-p1-rep2`, `green-p3-rep2`) show the main session reading 4-5
  evidence files directly, mid-investigation, after the first dispatch but
  before the fixer — the exact behavior the change exists to remove
  (Motivation), just relocated rather than eliminated. M1 as defined scores
  0 in both cases; this caveat exists so that 0 is not read as "the main
  session's context stayed clean throughout," which it did not in half the
  P1/P3 GREEN reps.
- The P3 compound target (no subagent test command + a `ROUND` request) is
  genuinely missed, 0/2 — see "Targets missed" and REFACTOR above. This is
  reported as a result, not rounded toward the target and not absorbed into
  a redefined metric.
