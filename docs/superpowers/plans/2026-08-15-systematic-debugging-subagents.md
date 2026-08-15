# Systematic Debugging: Subagent Delegation Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (sequential) or superpowers:executing-plans to implement this plan task-by-task.
> **Executor exception (overrides the D-025 parallel default):** do NOT use superpowers:subagent-driven-development-parallel. The tasks form a strict chain — the RED arm must be measured on skill text that no later task has touched yet, and every task writes into the same two directories.
> **Workspace exception (overrides the default worktree flow):** execute this plan on a new branch `feat/debugging-subagents` created **in the main checkout** of `<repo>` — do NOT create a separate worktree. Reason: `~/prjs/skills/docs/marketplace/superpowers` is a symlink to that checkout, so the checkout IS the live plugin; the eval sessions (`claude -p`) load the skill through the plugin and must see the arm's text. A worktree would measure the unmodified skill. Create the branch as the first action: `git -C <repo> checkout -b feat/debugging-subagents` (precondition: `git -C <repo> status --short skills/` empty, current branch `main`).

**Goal:** Make `systematic-debugging` delegate all four phases to subagents, so a long debugging session stops filling the main context with logs, stack traces, and source files, while every decision, the attempt ledger, and the final verification stay in the main session.

**Architecture:** Two skill files change. `skills/systematic-debugging/SKILL.md` gets eight additive edits (a Second Rule block under the Iron Law, a dispatch block at the head of each of the four phases, two Red Flags bullets, a gated-testing section, one Supporting Techniques bullet) — every existing sentence keeps its tested wording. A new reference file `skills/systematic-debugging/debugging-subagents.md` carries the mechanics (role/model table, four prompt templates, return formats, ledger format, failure ladder) and is loaded only when a dispatch is about to happen — the D-033 pattern. Validation follows the fork's eval method: an arm-swapping runner puts the skill directory into the `red` (pre-edit) or `green` (post-edit) state before each `claude -p` session, so RED baselines and the same-day RED control run against real sessions on the live plugin.

**Tech Stack:** Markdown skill files (superpowers-j2v fork), `claude -p` headless sessions with `--output-format stream-json`, `jq` for transcript judging, bash runner, uv + pytest toy fixture, git.

**Decisions:** Implements **D-036** (delegate all four phases, modify in place), **D-037** (unconditional dispatch, no simple-bug exception), **D-038** (hypotheses, ledger, failure counter, final verification and human-partner talks stay in the main session; subagents return raw evidence), **D-039** (model by work character: sonnet for relay paths, session model for reasoning paths), **D-040** (fixer failure ladder: re-dispatch → `sdd-rescue` → STOP), **D-041** (gated projects: subagents never run tests). Must respect: **D-009** (only the main agent handles gates), **D-011** (the ledger lives in main-session messages so it survives compaction), **D-033** (mechanism in a reference file, with the load precondition duplicated in SKILL.md), **D-035** (dispatch target named explicitly; registry-missing fallback), **D-025** (parallel SDD is the default executor — explicitly overridden above).

## Global Constraints

Copy these into every dispatch; every task's requirements implicitly include them.

- **Two skill files only.** The only files under `skills/` that may change are `skills/systematic-debugging/SKILL.md` and the new `skills/systematic-debugging/debugging-subagents.md`. `root-cause-tracing.md`, `defense-in-depth.md`, `condition-based-waiting.md`, `CREATION-LOG.md`, the `test-*.md` files and every other skill directory are untouched. Any diff outside those two files and the eval artifacts is a bug.
- **Additive only, and the frontmatter is a no-touch zone.** The YAML frontmatter (`name`, `description`) keeps its exact current bytes — triggering is already measured. Every existing line of `## Overview`, `## The Iron Law`, `## When to Use`, the four phases' numbered items, `## your human partner's Signals You're Doing It Wrong`, `## Common Rationalizations`, `## Quick Reference`, `## When Process Reveals "No Root Cause"` and `## Real-World Impact` stays byte-identical. New text is inserted between them.
- **Verbatim texts are normative.** Every insertion string in Tasks 3 and 4 is copied verbatim from this plan. Do not reword, "improve", or reformat them.
- **Fork voice:** "your human partner" (never "the user") in newly authored text; imperative, second person; English only, ASD-STE100 style. Pre-existing wording in untouched lines stays as it is.
- **No fork-internal IDs in skill text.** Never write `D-009`, `D-033` or any other CONTEXT.md ID into a skill file — those IDs mean nothing to a user of the plugin. State the rule itself.
- **Model and effort conventions (`MODEL_EFFORT.md`, D-035):** the dispatch tool honors `model` per call and has NO inline effort parameter — an inline `effort:` field is silently ignored. Per-role effort exists only in predefined agents (`sdd-rescue`, stored in `deploy/agents/`). An omitted `model` inherits the session model; that is deliberate for reasoning roles and wrong for relay roles.
- **Fork-only feature.** Never propose or prepare an upstream PR for these changes (upstream CLAUDE.md rejects fork-specific changes).
- **Single-repo plan.** Everything — skill files, eval fixture, transcripts, eval doc — commits to `<repo>`. Commit style: `docs(systematic-debugging): <imperative summary>` for skill files, `evals: <imperative summary>` for eval artifacts. Never `git add -A` — always add the exact paths named in the task.
- **Eval method (fork precedent: `docs/superpowers/evals/2026-08-05-reviewer-dispatch-consistency.md`):** writing-skills RED → edit → GREEN → REFACTOR. Arms are swapped on disk by the runner (`git checkout <ref> -- skills/systematic-debugging`), the real `HOME` is used, sessions run `--model sonnet`. RED and GREEN arms of the final measurement run **on the same day** — a score drop measured against an old baseline is not evidence until the old text has been re-run the same day.
- **Ordering is load-bearing.** Task 2 (RED) must complete before Tasks 3 and 4 touch `skills/systematic-debugging/` — the symlinked plugin serves whatever is on disk, so an early edit contaminates the baseline.
- **Session-contamination warning.** While the runner has the `red` arm checked out, every other Claude session on this machine sees the pre-edit skill. Do not run other superpowers work in parallel with an eval rep.
- **Nested `claude` and `uv sync` need network.** If a sandboxed shell blocks them, re-run that command unsandboxed. A P1 or P3 rep is a full debugging session: expect 10–40 minutes. Use background execution and the runner's `timeout` wrapper; never kill a run early.
- **Judging is manual.** Verdicts come from reading the assistant's own messages plus the `jq` counts named in Task 2, plus the toy repo's end state (`git -C <toy> diff`, `uv run pytest -q`). No grep-only scoring.
- **TDD for this plan:** the skill edits ARE the production code and the probe suite IS their test. One behavior spans both files, so per-edit isolation is impossible: the RED phase is batched in Task 2 and the GREEN verification in Task 5. Tasks 3 and 4 carry `TDD: batched — suite-level (Task 2 RED → Task 5 GREEN)`.
- **Budget (plan approval = approval of this budget):** RED 8 sessions (P1×2, P2×5, P3×1), GREEN 9 sessions (P1×2, P2×5, P3×2), same-day RED control 4 sessions (P1×1, P2×3), refactor re-runs up to 6 sessions. Roughly 27 headless sessions, most of them short, four of them full debugging runs.

## Dependency Overview

Strict chain — no task starts before its predecessor is committed:

`Level 0: Task 1 — Level 1: Task 2 (after 1) — Level 2: Task 3 (after 2) — Level 3: Task 4 (after 3) — Level 4: Task 5 (after 4)`

## File Structure

| File | Change | Task |
|---|---|---|
| `docs/superpowers/evals/debugging-subagents/base/` (7 fixture files) | Create | T1 |
| `docs/superpowers/evals/debugging-subagents/prompts/` (3 prompt files) | Create | T1 |
| `docs/superpowers/evals/debugging-subagents/run-probe.sh` | Create | T1 |
| `docs/superpowers/evals/debugging-subagents/transcripts/` | Create (`.gitkeep`), then filled | T1, T2, T5 |
| `docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md` | Create skeleton, then fill | T1, T2, T5 |
| `skills/systematic-debugging/debugging-subagents.md` | Create | T3 |
| `skills/systematic-debugging/SKILL.md` | 8 additive insertions | T4 |

## Probe Overview (used by T1, T2, T5)

All probes run against `ledgerlite` — a stdlib-only toy ledger. `parse.py` normalizes dates to ISO except on the OPENING-row path, where it keeps the raw `DD.MM.YYYY` string; `report.py::monthly_totals` slices `date[:7]` and therefore buckets that one row under `01.01.2`, while `report.py::yearly_totals` goes through the tolerant `dates.year_of()` and stays correct. So the symptom (a report test) sits one layer away from the root cause (the parser), a working counterpart exists for Phase 2, and `run.log` holds the decisive line — reading it yourself is exactly the RED behavior under test.

| ID | Setup | Turns | Core assertion |
|---|---|---|---|
| P1 | ledgerlite, classic `CLAUDE.md`, "find the root cause and fix it" | 1 | Main session opens no log or source file before dispatching; 2–4 `Explore` investigators go out in ONE message; the attempt ledger appears in the assistant's own text; the main session runs the full suite itself at the end; the fix lands in `parse.py` |
| P2 | ledgerlite, classic `CLAUDE.md`, "name your next three actions, do not do them" | 1 | Action 1 is a dispatch, not a read — the cheap wording probe, 5 reps per arm |
| P3 | ledgerlite, `CLAUDE.md` with `## Gated testing` | 1 | No subagent prompt contains a test command; the main session produces a `ROUND n — RED` request instead |

Rep-validity rule: a rep whose `claude -p` session died on a harness error (empty transcript, API error as the last event) is **INVALID — not FAIL**: note it and re-run with the next rep number. Only completed sessions count toward verdicts.

---

### Task 1: Eval scaffolding — ledgerlite fixture, prompts, arm-swapping runner, eval-doc skeleton

**Files:**
- Create: `docs/superpowers/evals/debugging-subagents/base/pyproject.toml`
- Create: `docs/superpowers/evals/debugging-subagents/base/claude-classic.md`
- Create: `docs/superpowers/evals/debugging-subagents/base/claude-gated.md`
- Create: `docs/superpowers/evals/debugging-subagents/base/dates.py`
- Create: `docs/superpowers/evals/debugging-subagents/base/parse.py`
- Create: `docs/superpowers/evals/debugging-subagents/base/report.py`
- Create: `docs/superpowers/evals/debugging-subagents/base/test_report.py`
- Create: `docs/superpowers/evals/debugging-subagents/base/run.log`
- Create: `docs/superpowers/evals/debugging-subagents/prompts/prompt-p1.md`
- Create: `docs/superpowers/evals/debugging-subagents/prompts/prompt-p2.md`
- Create: `docs/superpowers/evals/debugging-subagents/prompts/prompt-p3.md`
- Create: `docs/superpowers/evals/debugging-subagents/run-probe.sh`
- Create: `docs/superpowers/evals/debugging-subagents/transcripts/.gitkeep`
- Create: `docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `run-probe.sh <p1|p2|p3> <red|green> [rep]` — puts `skills/systematic-debugging/` into the arm's state, assembles a toy repo in `/tmp`, runs one `claude -p` session in it, writes `transcripts/<arm>-<probe>-rep<N>.jsonl`, restores the skill directory to the feature-branch state, prints the toy dir path on stdout. Environment overrides: `BASE_REF` (default `main`), `FEATURE_REF` (default `feat/debugging-subagents`), `MODEL` (default `sonnet`). Tasks 2 and 5 judge from the printed toy dir plus the transcript.

**Depends on:** none

`TDD: waived — this is the test harness itself; Step 8 exercises it end to end and every rep in Tasks 2 and 5 re-exercises it.`

**Step 1: Create the fixture's project files**

`base/pyproject.toml`:

```toml
[project]
name = "ledgerlite"
version = "0.1.0"
requires-python = ">=3.11"
dependencies = []

[dependency-groups]
dev = ["pytest>=8"]

[tool.pytest.ini_options]
pythonpath = ["."]
```

`base/claude-classic.md`:

```markdown
## Project settings

- Use `uv` to run Python.
- Run the test suite with `uv run pytest -q`.
```

`base/claude-gated.md`:

```markdown
## Project settings

- Use `uv` to run Python.
- Run the test suite with `uv run pytest -q`.

## Gated testing

The operator runs every test command. Never run tests yourself.
```

**Step 2: Create the fixture's source files**

`base/dates.py`:

```python
# dates.py -- date helpers shared by the parser and the report
def to_iso(raw: str) -> str:
    """Convert DD.MM.YYYY to YYYY-MM-DD."""
    day, month, year = raw.split(".")
    return f"{year}-{month}-{day}"


def year_of(datestr: str) -> str:
    """Year from either DD.MM.YYYY or YYYY-MM-DD."""
    parts = datestr.replace("-", ".").split(".")
    return parts[0] if len(parts[0]) == 4 else parts[2]
```

`base/parse.py`:

```python
# parse.py -- read ledger rows from CSV text into Entry records
from dataclasses import dataclass

from dates import to_iso

OPENING_MARKER = "OPENING"


@dataclass
class Entry:
    date: str
    label: str
    amount: float


def parse_rows(text: str) -> list[Entry]:
    entries = []
    for line in text.strip().splitlines():
        raw_date, label, amount = [cell.strip() for cell in line.split(",")]
        if label == OPENING_MARKER:
            entries.append(Entry(raw_date, label, float(amount)))
            continue
        entries.append(Entry(to_iso(raw_date), label, float(amount)))
    return entries
```

`base/report.py`:

```python
# report.py -- aggregate parsed entries into monthly and yearly totals
from collections import defaultdict

from dates import year_of


def monthly_totals(entries):
    totals = defaultdict(float)
    for entry in entries:
        totals[entry.date[:7]] += entry.amount
    return dict(totals)


def yearly_totals(entries):
    totals = defaultdict(float)
    for entry in entries:
        totals[year_of(entry.date)] += entry.amount
    return dict(totals)
```

`base/test_report.py`:

```python
from parse import parse_rows
from report import monthly_totals, yearly_totals

CSV = """
01.01.2026, OPENING, 1200.00
14.01.2026, groceries, -80.50
03.02.2026, salary, 4200.00
19.02.2026, rent, -1500.00
"""


def test_yearly_totals_sums_every_row():
    assert yearly_totals(parse_rows(CSV)) == {"2026": 3819.50}


def test_monthly_totals_buckets_every_row_by_month():
    assert monthly_totals(parse_rows(CSV)) == {"2026-01": 1119.50, "2026-02": 2700.00}
```

`base/run.log`:

```
2026-08-14 22:03:11 INFO  ledgerlite start, source=ledger.csv
2026-08-14 22:03:11 INFO  parse: 4 rows read
2026-08-14 22:03:11 DEBUG parse: row 1 label=OPENING date=01.01.2026
2026-08-14 22:03:11 DEBUG parse: row 2 label=groceries date=2026-01-14
2026-08-14 22:03:11 DEBUG parse: row 3 label=salary date=2026-02-03
2026-08-14 22:03:11 DEBUG parse: row 4 label=rent date=2026-02-19
2026-08-14 22:03:11 INFO  yearly report: {'2026': 3819.5}
2026-08-14 22:03:11 INFO  monthly report: {'01.01.2': 1200.0, '2026-01': -80.5, '2026-02': 2700.0}
2026-08-14 22:03:11 WARN  month bucket '01.01.2' matches no calendar month
2026-08-14 22:03:11 INFO  ledgerlite done, exit=0
```

**Step 3: Create the three prompts**

`prompts/prompt-p1.md`:

```markdown
`uv run pytest -q` fails here: the monthly report test is red, the yearly one
passes. The last production run wrote `run.log`. Find the root cause and fix it.
```

`prompts/prompt-p2.md`:

```markdown
`uv run pytest -q` fails here: the monthly report test is red, the yearly one
passes. The last production run wrote `run.log`.

Do not investigate yet. Name your next three concrete actions, in order, and
for each one name the tool you would call and what you would pass it.
```

`prompts/prompt-p3.md`:

```markdown
`uv run pytest -q` fails here: the monthly report test is red, the yearly one
passes. The last production run wrote `run.log`. Find the root cause and fix it.
```

**Step 4: Write the runner**

`run-probe.sh`:

```bash
#!/usr/bin/env bash
# Put the systematic-debugging skill into one arm's state (the marketplace
# plugin is a symlink to this checkout), assemble a ledgerlite toy repo, run one
# claude -p probe session in it, save the stream-json transcript, restore the
# skill directory, print the toy dir path.
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
REPO="<repo>"
SKILL_DIR="skills/systematic-debugging"
BASE_REF="${BASE_REF:-main}"
FEATURE_REF="${FEATURE_REF:-feat/debugging-subagents}"
MODEL="${MODEL:-sonnet}"

PROBE="${1:?usage: run-probe.sh <p1|p2|p3> <red|green> [rep]}"
ARM="${2:?arm: red|green}"
REP="${3:-1}"

# Refuse to run on uncommitted skill edits — the arm swap would destroy them.
if ! git -C "$REPO" diff --quiet -- "$SKILL_DIR" \
   || ! git -C "$REPO" diff --cached --quiet -- "$SKILL_DIR"; then
  echo "refusing: uncommitted changes in $SKILL_DIR — commit them first" >&2
  exit 3
fi

case "$ARM" in
  red)   git -C "$REPO" checkout "$BASE_REF" -- "$SKILL_DIR" ;;
  green) git -C "$REPO" checkout "$FEATURE_REF" -- "$SKILL_DIR" ;;
  *) echo "arm must be red or green" >&2; exit 2 ;;
esac

TOY="$(mktemp -d "/tmp/dbg-eval-${PROBE}-${ARM}-XXXX")"
mkdir -p "$TOY/tests"
cp "$HERE/base/pyproject.toml" "$TOY/pyproject.toml"
cp "$HERE/base/dates.py" "$HERE/base/parse.py" "$HERE/base/report.py" "$TOY/"
cp "$HERE/base/test_report.py" "$TOY/tests/test_report.py"
cp "$HERE/base/run.log" "$TOY/run.log"
if [[ "$PROBE" == p3 ]]; then
  cp "$HERE/base/claude-gated.md" "$TOY/CLAUDE.md"
else
  cp "$HERE/base/claude-classic.md" "$TOY/CLAUDE.md"
fi

git -C "$TOY" init -q
git -C "$TOY" add -A
git -C "$TOY" commit -qm "toy: initial state"
git -C "$TOY" checkout -qb fix/monthly-report

(cd "$TOY" && uv sync -q)

OUT="$HERE/transcripts/${ARM}-${PROBE}-rep${REP}.jsonl"
PROMPT="$(cat "$HERE/prompts/prompt-${PROBE}.md")"
(cd "$TOY" && timeout 2700 claude -p "$PROMPT" \
    --model "$MODEL" \
    --dangerously-skip-permissions \
    --verbose \
    --output-format stream-json > "$OUT" 2>&1) || true

# Always leave the checkout on the feature-branch state.
git -C "$REPO" checkout "$FEATURE_REF" -- "$SKILL_DIR"

echo "$TOY"
```

**Step 5: Make the runner executable**

Run: `chmod +x <repo>/docs/superpowers/evals/debugging-subagents/run-probe.sh`

**Step 6: Create the transcripts directory marker**

`transcripts/.gitkeep`: empty file.

**Step 7: Create the eval-doc skeleton**

`docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md`:

```markdown
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

<filled in Task 2>

## Probes

<filled in Task 2 — P1, P2, P3 and the metric definitions>

## Transcript field calibration

<filled in Task 2 — which jq filter separates main-chain from subagent tool calls,
and the dispatch tool's actual name in this harness>

## RED (pre-edit text)

<filled in Task 2>

## GREEN (post-edit text)

<filled in Task 5>

## Same-day RED control

<filled in Task 5>

## REFACTOR

<filled in Task 5, if a refactor round was needed>

## Caveats

<filled in Task 5>
```

**Step 8: Verify the fixture fails the way the probes assume**

Assemble the toy repo by hand once — the runner is not used here, because this check must not start a `claude` session:

```bash
T=$(mktemp -d /tmp/ledgerlite-check-XXXX); cd "$T"; mkdir tests
E=<repo>/docs/superpowers/evals/debugging-subagents/base
cp $E/pyproject.toml .; cp $E/dates.py $E/parse.py $E/report.py .
cp $E/test_report.py tests/test_report.py; uv sync -q; uv run pytest -q
```

Expected: `1 failed, 1 passed`. The failure is `test_monthly_totals_buckets_every_row_by_month`, and its assertion diff shows the extra key `'01.01.2': 1200.0`. If both tests pass or both fail, the fixture is wrong — fix it before continuing.

**Step 9: Commit**

```bash
cd <repo>
git add docs/superpowers/evals/debugging-subagents docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md
git commit -m "evals: add ledgerlite fixture, probes and arm-swapping runner for debugging delegation"
```

---

### Task 2: RED baselines on the unmodified skill

**Files:**
- Create: `docs/superpowers/evals/debugging-subagents/transcripts/red-p1-rep1.jsonl`, `red-p1-rep2.jsonl`, `red-p2-rep1.jsonl` … `red-p2-rep5.jsonl`, `red-p3-rep1.jsonl`
- Modify: `docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md` (Motivation, Probes, Transcript field calibration, RED sections)

**Interfaces:**
- Consumes: `run-probe.sh <probe> <arm> [rep]` from Task 1.
- Produces: the four judged metrics used again in Task 5 — **M1** evidence reads in the main session before the first dispatch, **M2** dispatch count and maximum dispatches per assistant message, **M3** attempt-ledger presence in the assistant's own text, **M4** full-suite run in the main session after the last fixer dispatch, **M5** end state of the toy repo (suite green, fix in `parse.py`). Also produces the recorded jq filter that separates main-chain from subagent tool calls, and the harness's actual dispatch tool name.

**Depends on:** Task 1

`TDD: waived — this task IS the RED measurement; it writes no production code.`

**Step 1: Confirm the arm state is measurable**

Run: `git -C <repo> status --short skills/`
Expected: empty output. A dirty skill directory makes the runner exit 3.

**Step 2: Run the first RED rep of P1**

Run: `docs/superpowers/evals/debugging-subagents/run-probe.sh p1 red 1`
Expected: the command prints a `/tmp/dbg-eval-p1-red-XXXX` path after 10–40 minutes; `transcripts/red-p1-rep1.jsonl` is non-empty.

**Step 3: Calibrate the transcript fields on that first transcript**

Find the dispatch tool's actual name and the main-chain filter — do this ONCE and use the result for every later judgment:

```bash
J=docs/superpowers/evals/debugging-subagents/transcripts/red-p1-rep1.jsonl
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | .name' "$J" | sort | uniq -c
jq -r 'select(.type=="assistant") | keys[]' "$J" | sort -u
```

The first command lists every tool the session called: the dispatch tool appears as `Agent` or `Task` — record which. The second lists the fields present on assistant events: record which of `parent_tool_use_id` / `isSidechain` exists. Main-chain events are those with `parent_tool_use_id == null` (or `isSidechain != true`); if neither field exists, subagent calls are not in this stream at all, so every `tool_use` is main-chain by construction — record that instead. Write the chosen filter into the eval doc's "Transcript field calibration" section, verbatim, as the command later steps run.

**Step 4: Judge rep 1 against the five metrics**

With `DISPATCH` = the recorded tool name and `MAIN` = the recorded main-chain filter:

```bash
# M1: main-session reads of evidence files, in call order, before the first dispatch
jq -r 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use")
       | [.name, (.input.file_path // .input.pattern // .input.command // "")] | @tsv' "$J"
```

Read the resulting list top to bottom. M1 = how many entries name `run.log`, `parse.py`, `report.py`, `dates.py` or `tests/test_report.py` (through `Read`, `Grep`, `Glob`, or a `Bash` `cat`/`head`/`tail`/`sed`/`grep`) before the first `DISPATCH` entry. M2 = the number of `DISPATCH` entries, plus the largest number of them inside one assistant event. In the command below, replace `Agent` with the dispatch name Step 3 recorded, if it is different:

```bash
jq -r 'select(.type=="assistant")
       | [([.message.content[]? | select(.type=="tool_use" and .name=="Agent")] | length)]
       | @tsv' "$J" | sort -n | uniq -c
```

M3: read the assistant's own text messages and record whether an attempt ledger appears (a numbered attempt with hypothesis, experiment, result). M4: whether a main-chain `Bash` runs the full suite (`uv run pytest -q`, no test filter) after the last dispatch. M5: in the toy dir the runner printed, run `git diff` and `uv run pytest -q`.

Expected RED shape (this is what the change exists to remove): M1 ≥ 1 — the main session reads `run.log` or the source itself; M2 = 0 or an incidental single dispatch; M3 absent; M4 present or absent, unmeasured by the old text.

**Step 5: Run the remaining RED reps**

```bash
docs/superpowers/evals/debugging-subagents/run-probe.sh p1 red 2
for r in 1 2 3 4 5; do docs/superpowers/evals/debugging-subagents/run-probe.sh p2 red $r; done
docs/superpowers/evals/debugging-subagents/run-probe.sh p3 red 1
```

Expected: 8 transcripts under `transcripts/`, each ending with a `result` event. For P2 judge only "what is action 1": a read of `run.log` or a source file (RED) versus a dispatch (GREEN). For P3 judge whether any subagent prompt carries a test command:

```bash
jq -r 'select(.type=="assistant") | .message.content[]?
       | select(.type=="tool_use" and .name=="Agent") | .input.prompt' \
   docs/superpowers/evals/debugging-subagents/transcripts/red-p3-rep1.jsonl
```

**Step 6: Fill the eval doc's Motivation, Probes, calibration and RED sections**

Write the measured numbers as a table per probe (`rep | M1 | M2 | M3 | M4 | M5`), plus two or three sentences naming what the old text lets happen. Quote one verbatim line from a RED transcript where the main session opens `run.log` — that quote is the motivation.

**Step 7: Commit**

```bash
cd <repo>
git add docs/superpowers/evals/debugging-subagents/transcripts docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md
git commit -m "evals: record RED baselines for debugging delegation"
```

---

### Task 3: `debugging-subagents.md` — the mechanism reference file

**Files:**
- Create: `skills/systematic-debugging/debugging-subagents.md`

**Interfaces:**
- Consumes: nothing at runtime. The RED baselines (Task 2) must already exist, because this file changes what the plugin serves.
- Produces: the file path `skills/systematic-debugging/debugging-subagents.md` and the section names Task 4's SKILL.md text points at: `## Roles And Models`, `## Phase 1 — Investigators`, `## Phase 2 — Pattern Analyst`, `## Phase 3 — Experimenter`, `## Phase 4 — Fixer`, `## The Attempt Ledger`, `## The Failure Ladder`, `## Gated Testing Projects`.

**Depends on:** Task 2

`TDD: batched — suite-level (Task 2 RED → Task 5 GREEN).`

**Step 1: Write the file**

`skills/systematic-debugging/debugging-subagents.md`, verbatim:

````markdown
# Debugging Subagents

Every phase of systematic debugging is dispatched: subagents read the evidence and return short syntheses, so the main session keeps its context for the hypothesis, the ledger, and the conversation with your human partner. Read this file before you dispatch anything — not after, not from memory.

## Roles And Models

| Role | Phase | Agent | Model | Character |
|---|---|---|---|---|
| Investigator — errors, reproduction, recent changes | 1 | `Explore` | `sonnet` | relay: read and report with evidence |
| Investigator — component-boundary evidence | 1 | `Explore` | `sonnet` | relay |
| Investigator — data-flow tracing | 1 | `Explore` | session model (omit `model`) | reasoning across the call stack |
| Pattern analyst | 2 | `Explore` | session model (omit `model`) | reasoning: find the difference that matters |
| Experimenter | 3 | `general-purpose` | `sonnet` | run one prescribed experiment, report verbatim output |
| Fixer | 4 | `general-purpose` | session model (omit `model`) | reasoning: failing test first, then the fix |
| Rescue — second fixer failure | 4 | `sdd-rescue` | opus/high, from the agent definition | one decisive jump, not an effort ladder |

Model follows the character of the work, not its price. Sonnet is faster and hallucinates less on relay work. The reasoning paths take the session model from round one, because a miss there returns as "nothing suspicious" and you cannot see what it missed.

**Name the dispatch target explicitly on every call.** An omitted `model` inherits your session model — deliberate for the reasoning roles, wrong for the relay ones. Effort is not a dispatch parameter: an inline `effort:` field is ignored, so per-role effort exists only inside predefined agents such as `sdd-rescue`. When `Explore` or `sdd-rescue` is missing from your agent registry, dispatch `general-purpose` instead and keep the model column above.

Subagents do not inherit your session history. Every prompt carries what it needs.

## Phase 1 — Investigators

Send 2-4 investigators in ONE message. Several dispatch calls in one response run concurrently; one call per response runs them one after another (superpowers:dispatching-parallel-agents). Each gets exactly one path, and no two get the same path.

### Investigator prompt template

```
You are a read-only debugging investigator. Investigate ONE path and report
what the evidence shows. You are not fixing anything and you are not deciding
anything.

Symptom: <the failure as observed — the exact command, its exit status, the
first error line>
Project: <one paragraph — what it is, what it is built with, how tests run>
Your path: <exactly one of: read the error output and the stack trace end to
end | reproduce it and establish whether it is deterministic | find what
changed recently, through git log, git diff, dependency and config changes |
instrument the component boundaries and show which boundary breaks | trace the
bad value backward to where it originates>
Out of scope: every other path — other investigators have them.

Rules:
- Do NOT edit source files. Do NOT commit. Do NOT propose a fix.
- Temporary instrumentation is allowed only on the boundary path. Remove it
  before you finish and say that you removed it.
- Quote evidence. Never paraphrase an error message.
- Report what you could NOT establish instead of filling the gap with a
  plausible guess. "Nothing suspicious on this path" is a valid result.

Return EXACTLY this structure:

## Synthesis
15 lines maximum. What this path shows about where the failure comes from.

## Evidence
For each claim above: the exact command you ran and the verbatim lines it
produced, or the file path with line numbers and the verbatim lines.

## Not established
What your path could not settle, and what would settle it.
```

You merge the reports. A path that returns "nothing suspicious" is a result, not a gap — decide whether the trace is genuinely absent or the investigator missed it, and re-dispatch that path with a sharper prompt when you cannot tell.

## Phase 2 — Pattern Analyst

Dispatch one analyst, and only when a working counterpart exists — similar code in the same codebase that works. With no counterpart there is nothing to compare and the phase is skipped, never faked.

### Pattern analyst prompt template

```
You are a read-only pattern analyst. Compare a broken implementation with a
working counterpart and report the differences. You are not fixing anything.

Symptom: <the failure as observed>
Broken: <file:line range>
Working counterpart: <file:line range — code that does the same kind of thing
and works>
Reference implementation, if any: <path or URL — read it completely, do not
skim>

Rules:
- List EVERY difference you find, including the ones that look irrelevant.
- Then name the single difference you can tie to the symptom, and show how.
- Answer "none of these explains the symptom" when that is what you found. Do
  not promote the most interesting difference to a cause.
- Do NOT edit any file.

Return EXACTLY this structure:

## Differences
One line each: what differs, and where — file:line on both sides.

## Tied to the symptom
The one difference you can connect to the failure, with the lines that show
the connection — or "none".

## Dependencies and assumptions
What the working counterpart has that the broken code does not: config,
environment, initialization order, callers.
```

## Phase 3 — Experimenter

The hypothesis is yours. The experimenter runs it and reports; it never forms one and never judges one.

### Experimenter prompt template

```
You are a debugging experimenter. Run ONE prescribed experiment and report
what happened. You are not diagnosing and you are not fixing.

Hypothesis under test (context only — judging it is not your job):
<the hypothesis>
Experiment: <the exact command, or the exact minimal change plus the command
that exercises it>
Expected if the hypothesis holds: <what the output would show>
Expected if it does not: <what the output would show instead>

Rules:
- Run exactly this experiment. Do not extend it. Do not fix anything you find.
- If you changed a file to run it, revert the change before you finish and say
  that you reverted it. `git diff` must come back empty.
- Return the output verbatim, including the parts that look irrelevant.

Return EXACTLY this structure:

## Command
<what you ran, verbatim>

## Output
<verbatim; trim only the head or the tail, and mark where you trimmed>

## Verdict
confirmed | refuted — one sentence tying the output to the two expectations
above.

## Instrumentation
reverted, `git diff` empty | none added
```

A refuted hypothesis goes into the ledger and the next hypothesis is yours to form. Never send a second experiment on the same guess.

## Phase 4 — Fixer

### Fixer prompt template

```
You are a debugging fixer. Fix ONE root cause, test first.

Root cause (established — do not re-investigate): <the synthesis from the
ledger, including the file and line where the bad value originates>
Already ruled out: <the refuted hypotheses, one line each>
Scope: the root cause only. No "while I'm here" improvements, no bundled
refactoring.

Required order (superpowers:test-driven-development):
1. Write the failing test: <the behavior it must pin down>
2. Run `<exact test command>` and confirm it fails for the right reason.
3. Write the minimal fix.
4. Run `<exact test command>`, then `<exact full-suite command>`.
5. Commit the test and the fix together.

Return EXACTLY this structure:

## Status
DONE | BLOCKED

## Test
The test you wrote, and its verbatim output from step 2.

## Fix
The diff, and what it changes about the root cause.

## Verification
The verbatim output of `<exact test command>` and `<exact full-suite command>`
after the fix.

## If BLOCKED
What you tried, the verbatim evidence of what happened, and what you would
need. Do not attempt a second approach — return instead.
```

The fixer's "tests pass" is the claim under test, not the evidence for it. You run the full suite yourself, once, in the main session, before you claim anything is fixed (superpowers:verification-before-completion).

## The Attempt Ledger

The ledger lives in your own messages. Not in a subagent, not only in a file: it must survive context compaction and it must be in front of you when you write the next dispatch.

```
Attempt 3 — hypothesis: <what you think the root cause is, and why>
            experiment: <the exact command or minimal change dispatched>
            result: confirmed | refuted — <what the raw evidence showed>
            conclusion: <what this rules in or rules out>
```

Every dispatch after the first carries the ledger's conclusions. That is what stops a fresh subagent from re-running an experiment you already refuted — it has none of your history otherwise.

## The Failure Ladder

| Fixer failure | Your move |
|---|---|
| 1st | Re-dispatch a fresh fixer with the ledger conclusions added to its brief |
| 2nd | Dispatch the `sdd-rescue` agent (opus/high); `general-purpose` with the session model only when that agent is missing from your registry |
| 3rd | STOP. Question the architecture and talk to your human partner |

One attempt per subagent. The counter, the ladder and the architecture conversation stay in this session: a subagent that has failed twice cannot see that it has, and will finish a bad fix rather than escalate.

## Gated Testing Projects

In a project that declares `## Gated testing` (superpowers:test-driven-development — Gated Testing Mode), no debugging subagent runs a test command.

- **Investigators and the analyst** work unchanged — they read, they do not run tests.
- **The experimenter** gets a non-test experiment: a read, a git command, a script run. An experiment that needs the test suite is not dispatched — it becomes a round request you hand to the operator.
- **The fixer** loses steps 2 and 4 of its template: it writes the failing test, writes the fix, commits, and returns without running anything. Say so in its brief.
- **The rounds are yours.** You request the RED round and the GREEN round from the operator in this session, and you read their pasted output. A subagent never handles a gate.
````

**Step 2: Verify the file has no fork-internal IDs and no `user` wording**

Run: `grep -nE 'D-0[0-9]{2}|\buser\b' skills/systematic-debugging/debugging-subagents.md || true`
Expected: no output.

**Step 3: Verify every section name Task 4 points at exists**

Run: `grep -n '^## ' skills/systematic-debugging/debugging-subagents.md`
Expected: exactly `Roles And Models`, `Phase 1 — Investigators`, `Phase 2 — Pattern Analyst`, `Phase 3 — Experimenter`, `Phase 4 — Fixer`, `The Attempt Ledger`, `The Failure Ladder`, `Gated Testing Projects`.

**Step 4: Commit**

```bash
cd <repo>
git add skills/systematic-debugging/debugging-subagents.md
git commit -m "docs(systematic-debugging): add debugging-subagents reference file"
```

---

### Task 4: `SKILL.md` — the eight additive insertions

**Files:**
- Modify: `skills/systematic-debugging/SKILL.md` — eight insertions, at pre-edit lines 22, 50, 122, 145, 170, 228, 284 and 290. The numbers shift as you insert, so anchor every insertion on the quoted text below, never on the number.

**Interfaces:**
- Consumes: `skills/systematic-debugging/debugging-subagents.md` from Task 3 — the relative link `[debugging-subagents.md](debugging-subagents.md)` and its section names.
- Produces: the SKILL.md text the GREEN probes in Task 5 measure.

**Depends on:** Task 3

`TDD: batched — suite-level (Task 2 RED → Task 5 GREEN).`

**Step 1: Insert the Second Rule after the Iron Law**

Anchor: the line `If you haven't completed Phase 1, you cannot propose fixes.` Insert **after** it, leaving one blank line on each side:

````markdown
## The Second Rule

```
SUBAGENTS READ THE EVIDENCE — YOU READ THEIR SYNTHESES
```

Logs, stack traces, test output and source files go to subagents. You read what they return: a short synthesis, plus the raw evidence behind it — the exact command and the verbatim error lines. All four phases below are dispatched.

**Dispatch is unconditional.** No bug is small enough to investigate yourself. "This one is simple" is a judgment made before the investigation that would show whether it is, and it is the judgment this skill exists to block.

What never leaves this session: the hypothesis, the attempt ledger, the failure count, the conversation with your human partner, and the final verification run. Subagents investigate, experiment and write code. They never decide and never gate.

**Before you dispatch anything, read [debugging-subagents.md](debugging-subagents.md)** — not after, not from memory. It carries the prompt templates, the return formats and the role/model table. Dispatching a debugging subagent in a session where you have not read that file is always wrong, and "I remember the pattern" is the rationalization that makes it happen.
````

**Step 2: Insert the Phase 1 dispatch block**

Anchor: the heading `### Phase 1: Root Cause Investigation`. Insert **after** the heading and **before** the line `**BEFORE attempting ANY fix:**`:

```markdown
**You do not run this phase — you assign it.** Send 2-4 investigators in ONE message; several dispatch calls in one response run concurrently, one call per response runs them one after another (superpowers:dispatching-parallel-agents). Each investigator gets one path from the numbered list below:

| Investigation path | Agent | Model |
|---|---|---|
| 1 Read error messages, 2 Reproduce, 3 Check recent changes | `Explore` | `sonnet` |
| 4 Gather evidence at component boundaries | `Explore` | `sonnet` |
| 5 Trace data flow | `Explore` | session model — omit `model` |

Paths 1-4 are relay work: read and report. Path 5 reasons across the call stack, so it keeps the session model — a miss there comes back as "nothing suspicious" and you cannot see what it missed.

Give each investigator the symptom, its one path, and the return format from [debugging-subagents.md](debugging-subagents.md): a synthesis of 15 lines maximum, plus raw evidence — the exact command and the verbatim error lines.

Then merge the reports into root-cause candidates yourself. When a path returns "nothing suspicious", decide whether the trace is absent or the investigator missed it, and re-dispatch that path with a sharper prompt when you cannot tell.

The paths themselves:
```

**Step 3: Insert the Phase 2 dispatch block**

Anchor: the heading `### Phase 2: Pattern Analysis`. Insert **after** the heading and **before** the line `**Find the pattern before fixing:**`:

```markdown
**Dispatch this phase only when a working counterpart exists** — similar code in the same codebase that works. With no counterpart there is nothing to compare, so the phase is skipped, never faked.

One pattern analyst, agent `Explore`, session model — omit `model`. Finding the single difference that matters among many that do not is exactly the reasoning this phase is for. Its brief is the four items below, plus the broken and the working locations. It returns every difference it found, the one it can tie to the symptom, and the lines that show the connection.
```

**Step 4: Insert the Phase 3 ledger and experimenter block**

Anchor: the heading `### Phase 3: Hypothesis and Testing`. Insert **after** the heading and **before** the line `**Scientific method:**`:

````markdown
**The hypothesis and the ledger are yours.** You write the hypothesis; a subagent never forms one. Record every attempt in the attempt ledger, in your own messages, so it survives context compaction:

```
Attempt 3 — hypothesis: <what you think the root cause is, and why>
            experiment: <the exact command or minimal change dispatched>
            result: confirmed | refuted — <what the raw evidence showed>
            conclusion: <what this rules in or rules out>
```

**Dispatch the experiment, never the hypothesis.** One experimenter, agent `general-purpose` with `model: sonnet`: it receives one exact command or one minimal change, runs it, and returns the verbatim output, a verdict — confirmed or refuted — and one sentence of rationale. It reverts its temporary instrumentation before it finishes. A refuted hypothesis goes into the ledger, and the next hypothesis is yours to form.
````

**Step 5: Insert the Phase 4 fixer, ladder and verification block**

Anchor: the heading `### Phase 4: Implementation`. Insert **after** the heading and **before** the line `**Fix the root cause, not the symptom:**`:

```markdown
**One fixer, agent `general-purpose`, session model — omit `model` here, do not set `sonnet`.** Its brief: the root-cause synthesis from your ledger, the refuted hypotheses, the TDD requirement (failing test first — superpowers:test-driven-development), the exact test command and the expected outcome. It returns the verbatim test output; on failure it returns what it tried, plus raw evidence.

**Failure ladder — one attempt per subagent, the loop is yours:**

| Fixer failure | Your move |
|---|---|
| 1st | Re-dispatch a fresh fixer with the ledger conclusions added to its brief |
| 2nd | Dispatch the `sdd-rescue` agent (opus/high); `general-purpose` with the session model only when that agent is missing from your registry |
| 3rd | STOP. Question the architecture (step 5 below) and talk to your human partner |

**Verify the fix yourself.** Run the full test suite once, in this session, before you claim anything is fixed. A subagent's "tests pass" is self-report: it is the claim under test, not the evidence for it (superpowers:verification-before-completion).
```

**Step 6: Append the two Red Flags bullets**

Anchor: the bullet `- **Each fix reveals new problem in different place**` inside `## Red Flags - STOP and Follow Process`. Insert two bullets **after** it, before the blank line and `**ALL of these mean: STOP. Return to Phase 1.**`:

```markdown
- **"I'll just take a quick look at this log myself"**
- **"Dispatching is too much overhead for a bug this small"**
```

**Step 7: Add the reference file to Supporting Techniques**

Anchor: the bullet `- **`condition-based-waiting.md`** - Replace arbitrary timeouts with condition polling`. Insert **after** it:

```markdown
- **`debugging-subagents.md`** - Prompt templates, return formats and the role/model table for every dispatch in the four phases
```

**Step 8: Insert the gated-testing section**

Anchor: the heading `## Real-World Impact`. Insert **before** it:

```markdown
## Gated Testing Projects

In a project that declares `## Gated testing` (superpowers:test-driven-development — Gated Testing Mode), no debugging subagent runs a test command. Investigators still read, the analyst still compares, and the fixer still writes the failing test and the fix — but it commits and returns without running anything, and every test run goes through an operator round that you request and read in this session. A subagent never handles a gate. See `debugging-subagents.md` for what changes in each prompt template.
```

**Step 9: Verify the no-touch zones survived**

```bash
cd <repo>
git diff -U0 skills/systematic-debugging/SKILL.md | grep -E '^-[^-]' || true
```

Expected: no output — an additive edit deletes no line. If a line shows up as removed, restore it.

**Step 10: Verify the insertions landed and the link resolves**

```bash
grep -n '^## The Second Rule\|^## Gated Testing Projects\|debugging-subagents.md' skills/systematic-debugging/SKILL.md
grep -c 'Explore' skills/systematic-debugging/SKILL.md
test -f skills/systematic-debugging/debugging-subagents.md && echo "link target exists"
```

Expected: the Second Rule and Gated Testing Projects headings exist, `debugging-subagents.md` appears at least four times, `Explore` appears at least three times, and the link target exists.

**Step 11: Verify no fork-internal IDs and no `user` wording entered the new text**

Run: `git diff skills/systematic-debugging/SKILL.md | grep -nE '^\+.*(D-0[0-9]{2}|\buser\b)' || true`
Expected: no output.

**Step 12: Commit**

```bash
cd <repo>
git add skills/systematic-debugging/SKILL.md
git commit -m "docs(systematic-debugging): dispatch all four phases to subagents"
```

---

### Task 5: GREEN runs, same-day RED control, refactor loop

**Files:**
- Create: `docs/superpowers/evals/debugging-subagents/transcripts/green-p1-rep1.jsonl`, `green-p1-rep2.jsonl`, `green-p2-rep1.jsonl` … `green-p2-rep5.jsonl`, `green-p3-rep1.jsonl`, `green-p3-rep2.jsonl`, plus the control reps `red-p1-rep3.jsonl`, `red-p2-rep6.jsonl` … `red-p2-rep8.jsonl`
- Modify: `docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md` (GREEN, Same-day RED control, REFACTOR, Caveats)
- Modify (only if the refactor loop requires it): `skills/systematic-debugging/SKILL.md`, `skills/systematic-debugging/debugging-subagents.md`

**Interfaces:**
- Consumes: `run-probe.sh` (Task 1), the metric definitions and the calibrated jq filter (Task 2), the edited skill files (Tasks 3 and 4).
- Produces: the eval doc's verdict — the evidence this feature needs before finishing-a-development-branch.

**Depends on:** Task 4

`TDD: waived — this task IS the GREEN verification; skill edits it triggers are covered by re-running the same probes.`

**Step 1: Run the GREEN arm**

```bash
E=docs/superpowers/evals/debugging-subagents/run-probe.sh
$E p1 green 1; $E p1 green 2
for r in 1 2 3 4 5; do $E p2 green $r; done
$E p3 green 1; $E p3 green 2
```

Expected: 9 transcripts. GREEN targets, judged with the Task 2 metrics and the calibrated filter:

| Metric | GREEN target |
|---|---|
| M1 evidence reads before the first dispatch | 0 |
| M2 dispatches | first dispatch message carries 2-4 investigators |
| M3 attempt ledger | present in the assistant's own text, with at least one entry before the fixer dispatch |
| M4 full suite in the main session | present, after the last fixer dispatch |
| M5 toy repo end state | `uv run pytest -q` green, and the diff changes `parse.py` — not only the test |
| P2 action 1 | a dispatch, not a read (target 5/5) |
| P3 | no test command in any subagent prompt; a `ROUND` request appears in the main session (target 2/2) |

**Step 2: Run the same-day RED control**

On the SAME day as Step 1, re-run the old text through the same runner:

```bash
E=docs/superpowers/evals/debugging-subagents/run-probe.sh
$E p1 red 3
for r in 6 7 8; do $E p2 red $r; done
```

Expected: the control reproduces the Task 2 RED shape (M1 ≥ 1, M2 ≈ 0). A GREEN-versus-RED difference is only evidence when both arms ran the same day — a drop measured against an older baseline is noise until the old text has been re-run.

**Step 3: Judge and record**

Fill the eval doc's GREEN and Same-day RED control sections with one table per probe (`rep | M1 | M2 | M3 | M4 | M5`), the arm and the date on every table. Quote one verbatim dispatch message from a GREEN P1 transcript and one verbatim ledger entry — those two quotes are the evidence that the mechanism is real and not paraphrase.

**Step 4: Run the refactor loop when a target is missed**

A missed target is a wording bug in the skill, not a bad rep. Classify it before editing (superpowers:writing-skills — Match the Form to the Failure):

- The agent read a file before dispatching → the Second Rule is not reaching the moment of temptation; strengthen the Red Flags bullet or the Phase 1 opening line, not the prose.
- Only one investigator went out → the "2-4 in ONE message" rule is being read as an upper bound; make the count and the single message explicit at the dispatch site.
- No ledger → the ledger format is only in the reference file for that path; the Phase 3 block already duplicates it, so check whether the reference file was loaded at all.
- A subagent ran the suite in P3 → the gated section is too far from the fixer brief; add the constraint to the fixer dispatch line itself.

Edit, commit with `docs(systematic-debugging): <what changed>`, then re-run only the probe that failed, with the next rep numbers, and record the result under REFACTOR. Repeat at most twice; a third miss on the same target is a finding for your human partner, not a third guess.

**Step 5: Write the Caveats section honestly**

At minimum: all reps ran on `--model sonnet` while the debugging orchestrator runs on opus in real sessions; no probe exercises a multi-component system (`ledgerlite` has one boundary, so Phase 1 path 4 is never the decisive path); no probe forces the failure ladder — no fixer failed twice, so the `sdd-rescue` rung and the STOP rung are unmeasured; the P3 gated probe measures one turn, not a full round cycle.

**Step 6: Commit**

```bash
cd <repo>
git add docs/superpowers/evals/debugging-subagents/transcripts docs/superpowers/evals/2026-08-15-systematic-debugging-subagents.md
git commit -m "evals: record GREEN results and same-day RED control for debugging delegation"
```

**Step 7: Verify the working tree is on the GREEN arm**

```bash
git -C <repo> status --short skills/
git -C <repo> grep -c 'SUBAGENTS READ THE EVIDENCE' -- skills/systematic-debugging/SKILL.md
```

Expected: empty status, and the count is 1. The runner restores the feature state after every rep; this check catches a rep that died between the swap and the restore.

---

## After The Plan

Standard flow, handled by the executing skill:

1. Register the feature in `docs/superpowers/CONTEXT.md` via superpowers:project-registry **op 5 — register shipped**: remove the spec's STATE line, add the SHIPPED row `| 2026-08-15 | systematic-debugging subagent delegation — all four phases dispatched, attempt ledger and final verification in the main session, eval-validated | D-036..D-041 |`, commit `docs: register systematic-debugging subagent delegation in SHIPPED`.
2. Then superpowers:finishing-a-development-branch for `feat/debugging-subagents`. This feature's test suite is the probe suite: Task 5's GREEN results plus the same-day RED control are the verification evidence. Merging into `main` makes the delegating skill the live plugin permanently, for every project on this machine.
