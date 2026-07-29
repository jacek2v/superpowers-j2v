# Eval: brainstorming deep research (parallel read-only research subagents)

Date: 2026-07-28
Skill(s): `brainstorming` (checklist steps 5 and 9, research prose, Process
Flow digraph, new `## Deep Research` section) + new reference file
`skills/brainstorming/research-subagents.md` — spec
`specs/2026-07-28-brainstorming-subagent-research-design.md`, decisions
D-029..D-033.
Method: writing-skills RED → edit → GREEN. Scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos) against the new `feedmix` fixture;
R2–R4 are multi-turn via `--session-id`/`--resume` with scripted answers.
Budget (human-approved via the implementation plan): baselines R1×2 R2×1
R3×1; GREEN R1×2 R2×2 R3×2 R4×1 (+re-runs after fixes). Branch:
`feat/brainstorm-deep-research` off `main`.

Scenario ↔ assertion map: R1→proposal exists and is its own message;
R2→acceptance-gated dispatch, trimmed list honoured, per-decision approval,
persistence; R3→no behavior change in well-known territory; R4→decline path.
Contamination caveat: toy sessions inherit the real plugin bootstrap; the
loaded skill content is the same text under test, so contamination points
toward the same text (2026-07-05 precedent).

## RED baselines

Ran against the unmodified skill (`git status --short skills/` empty before and
during this phase). Dispatch-tool name could not be positively verified — no
transcript dispatched anything. `grep -c '"name":"Task"' <file>.jsonl` returned
`0` for all 9 transcripts; the full tool-use inventory (`jq -r 'select(.type
=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' |
sort -u`) across every transcript shows only `Bash, Read, Skill, TaskCreate,
TaskUpdate, ToolSearch, Write` — no `Task`/`Agent`-shaped subagent-dispatch
tool anywhere. `TaskCreate`/`TaskUpdate` are the session's own todo-list
manager, not subagent dispatch — confirmed by their inputs (see R1 below).
No `docs/superpowers/research/` directory was created in any toy repo.

### STOP-rule determination

Brief's STOP rule: if both R1 baselines already propose parallel research
subagents as their own message and wait for acceptance (2/2), no failure was
demonstrated — STOP and defer to human partner instead of writing a RED
verdict or committing.

Evidence: **0/2**, not 2/2. Neither R1 rep's turn-1 message contains a
research-subagent proposal (no question list + named mode + subagent count),
and neither mentions subagents/dispatch/parallel at all — grep for
`subagent|równoległ|parallel|dispatch|research agent|task tool` (case
-insensitive) over every assistant text block in both transcripts returned
zero matches. **STOP rule does not trigger** — proceeding to record RED
verdicts and commit, per the brief's own instruction for the 0/2 case.

### R1 — full-text-search request, 3 open decisions (×2 reps, 1 turn each)

| Rep | Verdict | Evidence |
|---|---|---|
| 1 | FAIL (expected failure candidate) | Turn 1 ends after exactly **one** multiple-choice clarifying question (AND vs. exact-phrase matching); dispatch count `0`; no proposal text. Of the three open decisions (index storage, ranking, stemming/non-English) **zero are settled** — session ends mid-loop on the first question, before even reaching stemming/non-English. |
| 2 | FAIL (expected failure candidate) | Turn 1 ends after one multiple-choice clarifying question (API entry point A/B/C); dispatch count `0`; no proposal text. Zero of three decisions settled. |

Verbatim rationalizations (Polish, with English gloss):

- Rep 1, `TaskCreate` todo list (pending item, before any question is asked):
  `"Research sanity check (SQLite FTS5 stemming/tokenizers, stdlib-only)"`
  — a **solo, self-executed** checklist item, never phrased as a proposal to
  the human or a subagent dispatch. It runs a Bash one-liner
  (`python3 -c "import sqlite3; ... pragma compile_options"`) itself later in
  the same turn instead.
- Rep 2, assistant text: *"To w praktyce kieruje architekturę w stronę SQLite
  FTS5 (wbudowanego w moduł sqlite3 — zweryfikuję dostępność w kroku
  badawczym) zamiast zewnętrznego silnika typu Elasticsearch/Whoosh."*
  ("...this in practice steers the architecture toward SQLite FTS5 (built
  into the sqlite3 module — I'll verify availability in the research step)
  instead of an external engine like Elasticsearch/Whoosh.") — "research
  step" here means the agent checking itself, not proposing anything.
- Rep 2, `TaskCreate` todo list: `{"subject":"Research sanity check",
  "description":"Verify SQLite FTS5 availability in stdlib sqlite3 given
  D-001/D-002 constraints"}` — same self-executed framing, no
  acceptance/dispatch language.

Dispatch commands and output:
```
$ grep -c '"name":"Task"' baseline-r1-rep1.jsonl || true
0
$ grep -c '"name":"Task"' baseline-r1-rep2.jsonl || true
0
```
Final text commands and output — see full text in task-2-report.md; both end
on a bare clarifying question, not a proposal.

### R2 — R1 + turn 2 accepts with trimmed question list (×1 rep; judged turns 1–2 only, flow-validity rule)

| Turn | Verdict | Evidence |
|---|---|---|
| 1 | FAIL (same shape as R1) | One multiple-choice question (API entry point A/B/C); dispatch `0`; no proposal. |
| 2 | **INVALID beyond this point (expected)** | Scripted answer *"Yes, go ahead — but drop the stemming and non-English question, we only care about English for now. Run the rest."* was written assuming turn 1 had proposed research subagents to accept. It didn't. The agent reinterpreted "yes, go ahead" as approving interface option A and "drop the stemming question" as removing a topic from its own clarifying-question loop, then asked the next inline question (result format) unprompted. Per the brief this is the expected divergence point — turns 3–5 are not scored. |

Facts required by the brief, checked across the full 5-turn conversation
(beyond the scored window, for completeness):
- **Unprompted subagent dispatch:** none. `grep -c '"name":"Task"'` returns
  `0` on all of `baseline-r2-rep1.jsonl` and `-t2`..`-t5`.
- **Source citation for the FTS5 backend choice:** none. The only grounding
  is a self-run Bash probe in turn 1
  (`uv run python3 -c "...CREATE VIRTUAL TABLE t USING fts5(x)..."`)
  confirming FTS5 compiles into the local `sqlite3` — no URL, doc reference,
  or "per X" citation anywhere in the design text (turn 3's "## Podejścia"
  section).
- Turn 5 wrote and committed `docs/superpowers/specs/2026-07-29-full-text-
  search-design.md` (`git -C <toy> log --oneline` → `f9d8ea3 docs: add
  full-text search design spec`); no `docs/superpowers/research/` file or
  directory was ever created.

### R3 — well-known-territory request (`--json` flag), ×1 rep, 2 turns — healthy control

| Turn | Verdict | Evidence |
|---|---|---|
| 1 | PASS (no proposal, as expected) | One clarifying scope question (new spec vs. addendum to a nonexistent `list` command); dispatch `0`; no research-subagent language anywhere. |
| 2 | PASS | Agent presents the full design in one message and ends *"Wygląda dobrze? Jeśli tak, zapisuję spec do docs/superpowers/specs/2026-07-29-list-json-flag-design.md i aktualizuję CONTEXT.md."* (future tense — not yet written). Toy repo confirms: `git -C <toy> log --oneline` still shows only `toy: initial state`; no spec file added. |

Golden reference for GREEN R3 — the quick tier's shape (one scope question,
then a complete design in one message, nothing written until explicit
approval) must be reproduced unchanged after the skill edit.

Full per-command output, verbatim assistant texts, and toy-repo listings are
recorded in `.superpowers/sdd/task-2-report.md`.

## GREEN results
(to fill in T5)

## Refactor loop
(to fill in T5; "none needed" if empty)
