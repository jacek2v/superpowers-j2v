# Gated Round GREEN Implementer Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.
> **Executor exception (overrides the D-025 parallel default):** do NOT use superpowers:subagent-driven-development-parallel and do NOT use superpowers:subagent-driven-development. Two reasons. The tasks form a near-strict chain, because the RED baseline must be measured on skill text no later task has touched. And Tasks 2 and 7 are operator-driven live sessions — a subagent cannot drive them and cannot wait for them (a subagent ends the moment it stops calling tools).
> **Workspace exception (overrides the default worktree flow):** execute this plan on a new branch `feat/gated-green-implementer` created **in the main checkout** of `<repo>` — do NOT create a separate worktree. Reason: `~/prjs/skills/docs/marketplace/superpowers` is a symlink to that checkout, so the checkout IS the live plugin; the micro-test sessions load the skill through the plugin and must see the edited text. A worktree would measure the unmodified skill. Create the branch as the first action: `git -C <repo> checkout -b feat/gated-green-implementer` (precondition: `git -C <repo> status --short` empty, current branch `main`).

**Goal:** Make a gated-testing session that runs without SDD orchestration judge the round itself and then dispatch a subagent to write the change, so implementation work stops accumulating in the main Opus context.

**Architecture:** Four files change in the fork. A new bare-passthrough agent definition `deploy/agents/gated-green-implementer.md` carries sonnet/high; `deploy/agents/README.md` and `MODEL_EFFORT.md` register it. A new reference file `skills/test-driven-development/gated-round-dispatch.md` holds the dispatch prompt template — the only source of the subagent's instructions. `skills/test-driven-development/SKILL.md` gets three edits inside "Gated Testing Mode": a new subsection with the routing table and the SDD carve-out, a reworded "Valid RED" section, and one new rationalization row. Validation follows the fork's method: one RED baseline session before the skill text changes, three GREEN micro-test sessions after, all judged from the session transcript JSONL, plus an offline routing walkthrough over three real round outputs.

**Tech Stack:** Markdown skill files (superpowers-j2v fork), Claude Code interactive sessions, session transcript JSONL under `~/.claude/projects/`, `jq`, bash, git.

**Decisions:** Implements **D-043** (main session judges, sonnet/high implementer writes the GREEN change, INVALID RED and Gate GREEN failures go to `sdd-rescue`) and **D-044** (agent files carry model and effort only; role instructions live in the dispatch template). Must respect: **D-009** (only the main agent handles gates, never a subagent), **D-005** (no implementation before the phase RED gate confirms a valid RED), **D-010** (a later edit invalidates round evidence), **D-011** (every round and its verdict is recorded in the round ledger), **D-035** (name the dispatch target explicitly; fall back to `general-purpose` only when the agent is missing from the registry), **D-045** (a subagent cannot watch a `Monitor` — waiting stays in the main session), **D-046** ✗ (DO NOT rename the agents to effort-named ones such as `subagent-high` — this plan adds a role-named agent, which is the adopted direction).

**Registry state:** D-043 through D-046 are ALREADY recorded in `docs/superpowers/CONTEXT.md` (lines 63–66). The spec's Files table lists "CONTEXT.md — D-043 and D-044" as a change; that change already landed when the spec was approved. Task 7 therefore only moves the STATE line to SHIPPED. Do not add D-043 or D-044 again.

## Global Constraints

Copy these into every dispatch; every task's requirements implicitly include them.

- **Five files only.** The only files that may change under `skills/`, `deploy/` and the repo root are `skills/test-driven-development/SKILL.md`, the new `skills/test-driven-development/gated-round-dispatch.md`, the new `deploy/agents/gated-green-implementer.md`, `deploy/agents/README.md` and `MODEL_EFFORT.md`. Eval artifacts go under `docs/superpowers/evals/`; the registry change goes in `docs/superpowers/CONTEXT.md`. Any diff outside those paths is a bug.
- **Additive only in SKILL.md, and the frontmatter is a no-touch zone.** The YAML frontmatter (`name`, `description`) keeps its exact current bytes — triggering is already measured. Every line outside the three edits named in Task 5 stays byte-identical.
- **Verbatim texts are normative.** Every insertion string in this plan is copied verbatim into the file. Do not reword, "improve", or reformat them.
- **Fork voice:** "your human partner" (never "the user") in newly authored English text; imperative, second person; ASD-STE100 style. `MODEL_EFFORT.md` is a Polish document — new text there is Polish, matching the surrounding rows.
- **No fork-internal IDs in skill text.** Never write `D-009`, `D-043` or any other CONTEXT.md ID into a file under `skills/` or `deploy/`. State the rule itself. `MODEL_EFFORT.md` and `docs/superpowers/` may carry the IDs.
- **Model and effort conventions (`MODEL_EFFORT.md`, D-035):** the dispatch tool honors `model` per call and has NO inline effort parameter — an inline `effort:` field is silently ignored. Per-role effort exists only in a predefined agent file. An omitted `model` inherits the session model.
- **Fork-only feature.** Never propose or prepare an upstream PR for these changes (the upstream CLAUDE.md rejects fork-specific changes).
- **The client project is read-only.** `~/prjs/<gated project>` and its nested `<code repo>` are never written to. The probe clone in Task 1 uses `git clone`, which writes nothing into the source repository. The only exception is `.superpowers/rounds.md` in Task 2 and Task 7, which the micro-test session appends to; that file is git-excluded (`.git/info/exclude:18`), and every task that touches it backs it up first and restores it afterwards.
- **Never `claude -p --dangerously-skip-permissions`** for the micro-tests — the request classifier blocks it. The micro-test sessions are interactive sessions your human partner starts and drives.
- **Single-repo plan.** Everything commits to `<repo>`. Commit style: `docs(test-driven-development): <imperative summary>` for skill files, `docs(agents): <imperative summary>` for `deploy/agents/` and `MODEL_EFFORT.md`, `evals: <imperative summary>` for eval artifacts. Never `git add -A` — always add the exact paths named in the task.
- **TDD for this plan:** the skill and agent files ARE the production code and the micro-test probe IS their test. One behavior spans four files, so per-edit isolation is impossible: the RED phase is batched in Task 2 and the GREEN verification in Task 7. Tasks 3, 4 and 5 carry `TDD: batched — suite-level (Task 2 RED → Task 7 GREEN)`.
- **Ordering is load-bearing.** Task 2 (RED) must complete before Tasks 4 and 5 touch `skills/test-driven-development/` — the symlinked plugin serves whatever is on disk, so an early edit contaminates the baseline.
- **Session-contamination warning.** From the moment Task 5 commits until Task 7 finishes, every Claude session on this machine sees the new skill text. That is intended for the micro-tests. Do not run unrelated gated work in that window and read its behavior as normal.

## Dependency Overview

`Level 0: Tasks 1, 3 — Level 1: Task 2 (after 1) — Level 2: Task 4 (after 2) — Level 3: Task 5 (after 3, 4) — Level 4: Task 6 (after 5) — Level 5: Task 7 (after 2, 5, 6)`

## File Structure

| File | Change | Task |
|---|---|---|
| `docs/superpowers/evals/gated-green-implementer/probe-prompt.md` | Create | T1 |
| `docs/superpowers/evals/gated-green-implementer/judge-transcript.sh` | Create | T1 |
| `docs/superpowers/evals/gated-green-implementer/transcripts/.gitkeep` | Create | T1 |
| `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` | Create skeleton, then fill | T1, T2, T6, T7 |
| `deploy/agents/gated-green-implementer.md` | Create | T3 |
| `deploy/agents/README.md` | 4 edits | T3 |
| `MODEL_EFFORT.md` | 1 new section | T3 |
| `skills/test-driven-development/gated-round-dispatch.md` | Create | T4 |
| `skills/test-driven-development/SKILL.md` | 3 edits | T5 |
| `docs/superpowers/CONTEXT.md` | STATE line → SHIPPED row | T7 |

## Probe Overview (used by T1, T2, T7)

One probe, run as a fresh interactive session per repetition. It puts the session at a gate whose round has just finished and watches what the session does next.

| Item | Value |
|---|---|
| Session cwd | `<gated project>` — the only project with a `## Gated testing` block (`CLAUDE.md:31`) and real round files |
| Round output | `scripts/out/round1.out` — 13 lines, `Tests passed: 19, failed: 1`, `RESULT: FAIL`, one assertion failure on a missing debug row → a valid RED |
| Code worktree | `/tmp/ggi-probe` — a throwaway clone of `<code repo>` at `3df568b`, the RED commit the round was produced from |
| Reference GREEN | `e678901` in `<code repo>` — "Log the index backup rows with status debug", 1 file, 2 insertions, 1 deletion |
| Ledger | `<gated project>/.superpowers/rounds.md` — git-excluded, backed up and restored around every repetition |

Pass criteria, all three required per repetition:

1. **Selective read.** The session reads `round1.out` through `grep`, `sed`, `head` or `tail` — never a whole-file `Read`.
2. **Verdict before dispatch.** A write to `.superpowers/rounds.md` appears in the tool-call order BEFORE the first `Agent` dispatch.
3. **Dispatch, no self-written code.** The first `Agent` dispatch names `subagent_type: gated-green-implementer`, and the session itself issues no `Edit` or `Write` against a file under `/tmp/ggi-probe`.

A fail: the session writes the change itself, or it dispatches before the verdict.

Rep-validity rule: a repetition whose session died on a harness error, or in which the `test-driven-development` skill never loaded, is **INVALID — not FAIL**: note it and re-run with the next repetition number.

---

### Task 1: Probe fixture, transcript judge, eval-doc skeleton

**Files:**
- Create: `docs/superpowers/evals/gated-green-implementer/probe-prompt.md`
- Create: `docs/superpowers/evals/gated-green-implementer/judge-transcript.sh`
- Create: `docs/superpowers/evals/gated-green-implementer/transcripts/.gitkeep`
- Create: `docs/superpowers/evals/2026-08-29-gated-green-implementer.md`

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: `judge-transcript.sh <session.jsonl>` — prints three labelled evidence blocks, one per pass criterion, from a Claude Code session transcript. `probe-prompt.md` — the exact text your human partner pastes into a fresh session, plus the setup and teardown commands around it. `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` — the eval document Tasks 2, 6 and 7 fill in.

**Depends on:** none

`TDD: waived — this is the test harness itself; Step 5 exercises the judge end to end on a real transcript.`

**Step 1: Create the probe prompt and its setup commands**

Create `docs/superpowers/evals/gated-green-implementer/probe-prompt.md`:

````markdown
# Probe: gated round GREEN dispatch

One repetition = one fresh interactive Claude Code session. A subagent sees the
CLAUDE.md snapshot from the parent session start, so a fresh session per
repetition is required.

## Setup (run once per repetition, before the session starts)

```bash
rm -rf /tmp/ggi-probe
git clone --quiet --no-checkout "<gated project>/<code repo>" /tmp/ggi-probe
git -C /tmp/ggi-probe checkout --quiet 3df568b
cp "<gated project>/.superpowers/rounds.md" /tmp/ggi-rounds.bak
```

The clone reads the client repository and writes nothing into it. `3df568b` is
the RED commit `scripts/out/round1.out` was produced from.

## The session

Start it in `<gated project>`, with the operator's normal
model and effort. Paste exactly this, and nothing else:

```
Runda 1 skończona — wynik jest w scripts/out/round1.out. Faza: "index backup
rows move to status debug". Kod tej fazy leży w worktree /tmp/ggi-probe.
Prowadź dalej.
```

Then let the session run until it either dispatches a subagent or writes code
itself. Both outcomes end the repetition — do not steer it.

## Teardown (after the session ends)

```bash
cp /tmp/ggi-rounds.bak "<gated project>/.superpowers/rounds.md"
rm -rf /tmp/ggi-probe /tmp/ggi-rounds.bak
```

## Judging

The transcript is the newest file in
`~/.claude/projects/<gated project slug>/`:

```bash
ls -t ~/.claude/projects/<gated project slug>/*.jsonl | head -1
```

Copy it into `transcripts/<arm>-rep<N>.jsonl` (`arm` is `red` or `green`), then
run `./judge-transcript.sh transcripts/<arm>-rep<N>.jsonl` and read the three
evidence blocks against the pass criteria in the plan.
````

**Step 2: Create the transcript judge**

Create `docs/superpowers/evals/gated-green-implementer/judge-transcript.sh`:

```bash
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
tool_calls | awk -F'\t' '$1=="Edit" || $1=="Write" || $1=="NotebookEdit" { print "session write: " $3 }'
```

**Step 3: Make the judge executable**

Run: `chmod +x docs/superpowers/evals/gated-green-implementer/judge-transcript.sh`

**Step 4: Create the transcripts directory**

Run: `mkdir -p docs/superpowers/evals/gated-green-implementer/transcripts && touch docs/superpowers/evals/gated-green-implementer/transcripts/.gitkeep`

**Step 5: Verify the judge runs on a real transcript**

Run:

```bash
docs/superpowers/evals/gated-green-implementer/judge-transcript.sh "$(ls -t ~/.claude/projects/<gated project slug>/*.jsonl | head -1)"
```

Expected: three `==` headings print, and the C3 block lists at least one `dispatch:` or `session write:` line. That transcript is an unrelated past session, so its content proves nothing about the probe — it only proves the `jq` and `awk` filters match the transcript schema.

If the C3 block is empty for every transcript in that directory, the schema assumption is wrong: re-check with `jq -c 'select(.type=="assistant") | .message.content[]? | select(.type=="tool_use") | {name, input_keys:(.input|keys)}'` and fix the filters before continuing.

**Step 6: Create the eval-doc skeleton**

Create `docs/superpowers/evals/2026-08-29-gated-green-implementer.md`:

```markdown
# Eval: gated round GREEN implementer

Spec: [2026-08-29-gated-green-implementer-design.md](../specs/2026-08-29-gated-green-implementer-design.md)
Decisions: D-043, D-044

Method: one probe (see `gated-green-implementer/probe-prompt.md`), one fresh
interactive session per repetition, judged from the session transcript with
`gated-green-implementer/judge-transcript.sh`. RED arm runs on the skill text
before the edits, GREEN arm after.

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
```

**Step 7: Commit**

```bash
git add docs/superpowers/evals/gated-green-implementer docs/superpowers/evals/2026-08-29-gated-green-implementer.md
git commit -m "evals: add the gated GREEN dispatch probe, transcript judge and eval skeleton"
```

---

### Task 2: RED baseline — one repetition on the unmodified skill

**Files:**
- Modify: `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` (fill the "RED arm" section)
- Create: `docs/superpowers/evals/gated-green-implementer/transcripts/red-rep1.jsonl`

**Interfaces:**
- Consumes: `probe-prompt.md` and `judge-transcript.sh` from Task 1.
- Produces: the RED verdict recorded in the eval document, and a confirmation that the probe reaches the gate logic at all. Tasks 4, 5 and 7 depend on this having run first.

**Depends on:** Task 1

`TDD: this IS the RED step of the whole plan.`

This task has two purposes. It measures the current behavior — the session writes the GREEN change itself, which is the defect the spec's Problem section names. And it validates the probe: if the `test-driven-development` skill never loads, or the session never reaches a verdict, the probe measures nothing and must be fixed before the GREEN arm.

**Step 1: Confirm the skill text is unmodified**

Run: `git -C <repo> diff main --stat -- skills/test-driven-development deploy/agents`

Expected: empty output. Any diff here means a later task already ran and the baseline is contaminated — stop and reset.

**Step 2: Run the setup commands**

Run the "Setup" block from `docs/superpowers/evals/gated-green-implementer/probe-prompt.md` verbatim.

**Step 3: Ask your human partner to run one repetition**

Post this and WAIT:

```
Frame — superpowers-j2v, warstwa pomiarowa planu „gated GREEN implementer".
Potrzebuję jednej sesji bazowej (RED) na NIEZMIENIONYM tekście skilla, żeby
zmierzyć, co sesja robi dzisiaj przy bramce.

Proszę o uruchomienie jednej świeżej sesji Claude Code:
- katalog startowy: <gated project>
- model i effort: Twoje zwykłe ustawienia
- wklej dokładnie ten tekst i nic więcej:

Runda 1 skończona — wynik jest w scripts/out/round1.out. Faza: "index backup
rows move to status debug". Kod tej fazy leży w worktree /tmp/ggi-probe.
Prowadź dalej.

Sesja ma biec bez sterowania, aż albo wyśle subagenta, albo sama napisze kod.
Potem daj mi znać — resztę zrobię z transkryptu.
```

**Step 4: Copy the transcript and judge it**

Run:

```bash
cp "$(ls -t ~/.claude/projects/<gated project slug>/*.jsonl | head -1)" docs/superpowers/evals/gated-green-implementer/transcripts/red-rep1.jsonl
docs/superpowers/evals/gated-green-implementer/judge-transcript.sh docs/superpowers/evals/gated-green-implementer/transcripts/red-rep1.jsonl
```

Expected RED outcome: the C3 block shows `session write:` lines under `/tmp/ggi-probe` and no `dispatch: gated-green-implementer` line. That is the defect, measured.

If instead the session dispatched nothing AND wrote nothing — for example it only answered in prose, or the skill never loaded — the repetition is INVALID. Fix the probe prompt in `probe-prompt.md` (state the phase and the wanted behavior more plainly), commit the fix, and re-run this task with `red-rep2.jsonl`.

**Step 5: Run the teardown commands**

Run the "Teardown" block from `probe-prompt.md` verbatim.

**Step 6: Fill the RED arm section**

Replace the line `TO BE FILLED BY TASK 2.` under `## RED arm` in `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` with, filling the bracketed parts from the judge output:

```markdown
Date: 2026-08-29. Skill text: `main`, before the edits. One repetition,
transcript `gated-green-implementer/transcripts/red-rep1.jsonl`.

| Criterion | Result | Evidence |
|---|---|---|
| 1 — selective read | [PASS/FAIL] | [the C1 lines] |
| 2 — verdict before dispatch | [PASS/FAIL] | [the C2 lines] |
| 3 — dispatch, no self-written code | [PASS/FAIL] | [the C3 lines] |

RED verdict: [one sentence — what the session did instead of dispatching].
```

**Step 7: Commit**

```bash
git add docs/superpowers/evals/2026-08-29-gated-green-implementer.md docs/superpowers/evals/gated-green-implementer/transcripts/red-rep1.jsonl
git commit -m "evals: record the RED baseline for the gated GREEN dispatch"
```

---

### Task 3: Agent definition, agent README, model/effort registry

**Files:**
- Create: `deploy/agents/gated-green-implementer.md`
- Modify: `deploy/agents/README.md:3-4`, `:14`, `:22`, `:26-28`
- Modify: `MODEL_EFFORT.md` — new section after "## Recenzja poza SDD"

**Interfaces:**
- Consumes: nothing from other tasks.
- Produces: the dispatch name `gated-green-implementer` (sonnet / high), referenced by Task 4's template and Task 5's routing table. Frontmatter fields: `name: gated-green-implementer`, `model: sonnet`, `effort: high`.

**Depends on:** none

`TDD: batched — suite-level (Task 2 RED → Task 7 GREEN)`

**Step 1: Create the agent definition**

Create `deploy/agents/gated-green-implementer.md`:

```markdown
---
name: gated-green-implementer
description: Fully-capable coding subagent for gated testing mode — writes the change after the main session judges a round (sonnet, high effort)
model: sonnet
effort: high
---

You are a fully-capable coding subagent dispatched by the test-driven-development skill. Follow the dispatched prompt exactly. You have full tool access.
```

The body carries no role instructions on purpose. The agent file carries model and effort; the dispatch template stays the only source of instructions.

**Step 2: Widen the README's opening sentence**

In `deploy/agents/README.md`, replace lines 3–9:

```markdown
Definitions the `subagent-driven-development` and
`subagent-driven-development-parallel` skills dispatch by name. They
exist to carry a **per-role reasoning effort**: the Agent/Task dispatch tool
honors `model` per call but has **no inline effort parameter** — an inline
`effort:` field is silently ignored. The only channel for per-role effort is a
predefined agent whose frontmatter sets `effort`, which is what these two files
are.
```

with:

```markdown
Definitions the `subagent-driven-development`,
`subagent-driven-development-parallel` and `test-driven-development` skills
dispatch by name. They exist to carry a **per-role reasoning effort**: the
Agent/Task dispatch tool honors `model` per call but has **no inline effort
parameter** — an inline `effort:` field is silently ignored. The only channel
for per-role effort is a predefined agent whose frontmatter sets `effort`,
which is what these files are.
```

**Step 3: Add the table row**

In `deploy/agents/README.md`, after line 14 (the `sdd-rescue.md` row), add:

```markdown
| `gated-green-implementer.md` | `gated-green-implementer` | sonnet / high | gated testing mode without SDD: the change after a judged round |
```

**Step 4: Update the Install section**

In `deploy/agents/README.md`, replace line 22:

```markdown
from the repo. To make the `sdd-reviewer` / `sdd-rescue` dispatch names resolve,
```

with:

```markdown
from the repo. To make the dispatch names in the table above resolve,
```

Then replace lines 26 and 28:

```bash
cp sdd-reviewer.md sdd-rescue.md ~/.claude/agents/        # user-level (all projects)
# or, project-scoped:
cp sdd-reviewer.md sdd-rescue.md <project>/.claude/agents/
```

with:

```bash
cp sdd-reviewer.md sdd-rescue.md gated-green-implementer.md ~/.claude/agents/   # user-level
# or, project-scoped:
cp sdd-reviewer.md sdd-rescue.md gated-green-implementer.md <project>/.claude/agents/
```

**Step 5: Register the roles in MODEL_EFFORT.md**

In `MODEL_EFFORT.md`, after the "## Recenzja poza SDD" section — that is, after the paragraph ending `([D-035](docs/superpowers/evals/2026-08-05-reviewer-dispatch-consistency.md)).` and before the line `Uzasadnienia:` — insert:

```markdown
## Tryb gated testing bez orkiestracji SDD

| Rola | Model / effort | Skąd |
|---|---|---|
| implementer GREEN po ważnym RED | sonnet / high | agent `gated-green-implementer` |
| naprawa testów po INVALID RED | opus / high | agent `sdd-rescue` |
| naprawa kodu po nieudanym Gate GREEN | opus / high | agent `sdd-rescue` |

Sesja główna czyta wynik rundy, orzeka werdykt i dopisuje go do rejestru rund,
dopiero potem wysyła subagenta (D-043). Gdy fazę prowadzi
`subagent-driven-development` albo jego kopia równoległa, obowiązuje routing
tamtego skilla, a ta tabela nie działa.

```

**Step 6: Verify the agent file parses as frontmatter**

Run:

```bash
head -6 deploy/agents/gated-green-implementer.md
```

Expected: the first line is `---`, and the block holds `name`, `description`, `model: sonnet`, `effort: high`, closed by `---`.

**Step 7: Ask your human partner to install the agent**

The dispatch name resolves only from an agents directory Claude Code loads, and `~/.claude/` sits outside this repository. Post this and WAIT:

```
Frame — superpowers-j2v, zadanie 3 planu „gated GREEN implementer". Nowy plik
agenta jest w repo, ale nazwa `gated-green-implementer` zadziała dopiero po
skopiowaniu go do Twojego katalogu agentów. To zapis poza repozytorium, więc
proszę o Twoją zgodę albo o uruchomienie polecenia u siebie:

cp <repo>/deploy/agents/gated-green-implementer.md ~/.claude/agents/

Rejestr agentów przeładowuje się dopiero w nowej sesji, więc mikrotesty z
zadania 7 i tak startują w świeżych sesjach.
```

**Step 8: Verify the installed copy**

Run: `ls -l ~/.claude/agents/`

Expected: three files — `sdd-rescue.md`, `sdd-reviewer.md`, `gated-green-implementer.md`.

**Step 9: Commit**

```bash
git add deploy/agents/gated-green-implementer.md deploy/agents/README.md MODEL_EFFORT.md
git commit -m "docs(agents): add the gated-green-implementer agent (sonnet/high)"
```

---

### Task 4: Dispatch prompt template

**Files:**
- Create: `skills/test-driven-development/gated-round-dispatch.md`

**Interfaces:**
- Consumes: the dispatch name `gated-green-implementer` from Task 3.
- Produces: the reference file `skills/test-driven-development/gated-round-dispatch.md`, linked from SKILL.md in Task 5 as `[gated-round-dispatch.md](gated-round-dispatch.md)`.

**Depends on:** Task 2

`TDD: batched — suite-level (Task 2 RED → Task 7 GREEN)`

**Step 1: Create the template file**

Create `skills/test-driven-development/gated-round-dispatch.md` with exactly this content:

````markdown
# Gated Round Dispatch

Use this at a gate in Gated Testing Mode, after you judged the round and wrote
the verdict into the round ledger. One template serves all three dispatch
targets — only the verdict line and the wanted-behavior block change.

| Verdict | Dispatch target | Model / effort |
|---|---|---|
| Valid RED | `gated-green-implementer` | sonnet / high |
| INVALID RED — the tests are wrong | `sdd-rescue` | opus / high |
| Gate GREEN failure — the code is wrong | `sdd-rescue` | opus / high |

Pass no path to the plan and no path to the spec. When a plan exists, paste the
one relevant task block into "Wanted behavior". The subagent gets exactly what
it needs and nothing else.

```
Subagent (gated-green-implementer | sdd-rescue):
  description: "Round <n> <verdict> — <short subject>"
  prompt: |
    You write code for a project whose tests run behind a gate. You never run
    the tests. The main session owns the gate and holds the round evidence.

    ## Work from

    [WORKTREE_PATH]

    ## Round verdict

    Round <n> — <Valid RED | INVALID RED | Gate GREEN failure>, phase "<name>".
    The main session judged this verdict and recorded it in the round ledger.

    ## What the round showed

    [The summary counts and every failure block, verbatim from the round
    output. Nothing else from that file.]

    ## Wanted behavior

    [What the code must do, written by the main session. When a plan exists,
    the relevant task block goes here verbatim.]

    ## Rules

    - Do NOT edit any test file. The tests state the required behavior.
      This rule is lifted for an INVALID RED repair, and then it inverts: you
      fix the tests and you touch no production code.
    - Do NOT run the test suite. It is gated — you cannot reach the test system.
    - Write the smallest change that produces the wanted behavior.
    - Follow the patterns already in the files you touch.

    ## Commit

    Commit in [WORKTREE_PATH]. Within a phase every RED commit lands before
    every GREEN commit, so your commit is a GREEN commit — unless this dispatch
    is an INVALID RED repair, which is a RED commit.

    ## Report back, under 15 lines

    - **Status:** DONE | DONE_WITH_CONCERNS | BLOCKED
    - Files changed
    - Diff summary — one line per file, what changed
    - Commit subject and short SHA
    - Your concerns, if any

    Use BLOCKED when the wanted behavior needs a decision you cannot make from
    the material above. Put the specifics in your final message; the main
    session acts on it directly.
```

**After the report comes back:** inspect `git log -1` and the diff yourself. A
subagent report never closes a task.

**The commit invalidates the round output that produced it.** Request a new
round; do not reuse the old one.

**BLOCKED from `gated-green-implementer`** escalates to `sdd-rescue` — one jump,
not an effort ladder.

**A missing agent name** — `gated-green-implementer` or `sdd-rescue` not in your
registry — falls back to `general-purpose` with your session model. The agent
definitions live under [deploy/agents/](../../deploy/agents/); install them per
that directory's README so the names resolve.
````

**Step 2: Verify the file has no broken relative link**

Run:

```bash
ls skills/test-driven-development/gated-round-dispatch.md deploy/agents/README.md
```

Expected: both paths print. `../../deploy/agents/` resolves from `skills/test-driven-development/` to `deploy/agents/`.

**Step 3: Commit**

```bash
git add skills/test-driven-development/gated-round-dispatch.md
git commit -m "docs(test-driven-development): add the gated round dispatch template"
```

---

### Task 5: SKILL.md — routing subsection, reworded Valid RED, new rationalization row

**Files:**
- Modify: `skills/test-driven-development/SKILL.md:433-441` (retitle and reword), `:441` (insert the new subsection after it), `:466` (append one table row)

**Interfaces:**
- Consumes: the dispatch name `gated-green-implementer` from Task 3, and the file `gated-round-dispatch.md` from Task 4.
- Produces: the behavior the Task 7 micro-tests measure.

**Depends on:** Task 3, Task 4

`TDD: batched — suite-level (Task 2 RED → Task 7 GREEN)`

Three edits, all inside "Gated Testing Mode". Everything else in the file stays byte-identical.

**Step 1: Retitle and reword the Valid RED section**

Replace this block (currently lines 433–441):

```markdown
### Valid RED — judge every new test in the output

| Round shows | Verdict | Action |
|---|---|---|
| Assertion failure on the missing behavior | Valid RED | proceed |
| Clean "object/module does not exist" error | Valid RED | proceed |
| Test-file syntax error, fixture/collection error, connection error | INVALID | fix the tests → re-round narrowed to the affected files |

Gate GREEN failures: fix the code — never the test — then a narrowed or full GREEN re-round. A phase ends only green.
```

with:

```markdown
### Valid RED — judge every new test in the output, then dispatch

| Round shows | Verdict | Action |
|---|---|---|
| Assertion failure on the missing behavior | Valid RED | dispatch the change |
| Clean "object/module does not exist" error | Valid RED | dispatch the change |
| Test-file syntax error, fixture/collection error, connection error | INVALID | dispatch the test repair → re-round narrowed to the affected files |

Gate GREEN failures: dispatch a code fix — never a test change — then a narrowed or full GREEN re-round. A phase ends only green.
```

**Step 2: Insert the new subsection**

After the reworded "Gate GREEN failures" line from Step 1, and before `### Evidence Freshness`, insert:

```markdown
### Who Writes the Change

You judge the round. A subagent writes the code. Dispatch only after the verdict is in the round ledger, never before.

| Verdict | Dispatch | Model / effort |
|---|---|---|
| Valid RED | `gated-green-implementer` | sonnet / high |
| INVALID RED — the tests are wrong | `sdd-rescue` | opus / high |
| Gate GREEN failure — the code is wrong | `sdd-rescue` | opus / high |

Build the prompt from [gated-round-dispatch.md](gated-round-dispatch.md). It is the only source of the subagent's instructions. The agent definitions live under [deploy/agents/](../../deploy/agents/) — install them per that directory's README so the dispatch names resolve. A name missing from your registry falls back to `general-purpose` with your session model.

Three things never move to a subagent: the round verdict, the round ledger entry, and the conversation with your human partner.

Read the round output yourself, and selectively — the result line, the counts, the failure blocks. The wanted lines are a handful. A subagent that reads them for you adds a dispatch before every gate and saves nothing.

The subagent's commit invalidates the round output that produced it. Inspect `git log -1` and the diff, then request the next round. A subagent report never closes a task.

BLOCKED from `gated-green-implementer` escalates to `sdd-rescue` — one jump, not an effort ladder.

**Carve-out:** when `subagent-driven-development` or `subagent-driven-development-parallel` runs the phase, that skill's own routing governs and this subsection does not apply.
```

**Step 3: Append the rationalization row**

At the end of the "### Gated Rationalizations" table — after the current last row, which begins `| "I'll run the gated command once` — append:

```markdown
| "It is one line — dispatching a subagent is slower than typing it" | The session judges the round. The subagent writes the code. Implementation work in the main context is paid for by every later turn. |
```

**Step 4: Verify the diff is exactly three edits**

Run: `git diff --numstat -- skills/test-driven-development/SKILL.md`

Expected: `27	5	skills/test-driven-development/SKILL.md`, give or take two on either number for blank-line placement. The five deletions are the section heading, the three table rows and the "Gate GREEN failures" line from Step 1. A larger deletion count means a byte-identical line was reflowed — undo it.

**Step 5: Verify the frontmatter is untouched**

Run: `git diff -- skills/test-driven-development/SKILL.md | grep "^@@"`

Expected: every hunk header points at a line in the 430s or 460s. No hunk touches lines 1–4.

**Step 6: Commit**

```bash
git add skills/test-driven-development/SKILL.md
git commit -m "docs(test-driven-development): dispatch the change after a judged round"
```

---

### Task 6: Offline routing check on three real round outputs

**Files:**
- Modify: `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` (fill the "Offline routing check" section)

**Interfaces:**
- Consumes: the routing table from Task 5's SKILL.md subsection.
- Produces: the recorded walkthrough Task 7's verdict section cites.

**Depends on:** Task 5

`TDD: waived — this is a documentation walkthrough over existing files; it writes no production code.`

**Spec correction, verified 2026-08-29:** the spec names `scripts/out/round1b.out` for this check and calls it "1766 lines". The file is 1766 **bytes** and 6 lines, and it ends `Tests passed: 14, failed: 0` / `RESULT: PASS`. It is neither large nor an INVALID RED, so it cannot serve either goal. This task uses three other real files from the same directory, which together cover all three routing rows and a genuinely large output.

| File | Lines | Counts | What it is | Expected target |
|---|---|---|---|---|
| `scripts/out/round1.out` | 13 | 19 passed, 1 failed | assertion failure on a missing debug row | `gated-green-implementer` |
| `scripts/out/obj_red5.out` | 44 | 361 passed, 5 failed | one failure is `Error occurred in Describe block — Cannot bind argument to parameter 'Path' because it is null` — a fixture error | `sdd-rescue` |
| `scripts/out/cat_green1.out` | 319 | 1464 passed, 20 failed | a full-suite GREEN round that failed | `sdd-rescue` |

**Step 1: Read each file selectively**

Run, one command per file:

```bash
grep -nE "^\[FAIL\]|Tests passed|^RESULT" "<gated project>/scripts/out/round1.out"
grep -nE "^\[FAIL\]|Tests passed|^RESULT" "<gated project>/scripts/out/obj_red5.out"
grep -nE "^\[FAIL\]|Tests passed|^RESULT" "<gated project>/scripts/out/cat_green1.out"
```

Expected: one `[FAIL]` line for `round1.out`, five for `obj_red5.out`, twenty for `cat_green1.out`, each followed by its counts and `RESULT` line. For `cat_green1.out` this returns 22 lines out of 319 — the selective read stays sufficient on the largest real round output.

**Step 2: Read the failure detail for the two ambiguous files**

Run:

```bash
sed -n '35,42p' "<gated project>/scripts/out/obj_red5.out"
```

Expected: the `Error occurred in Describe block` block with `Cannot bind argument to parameter 'Path' because it is null`. A fixture error, so the verdict is INVALID and the target is `sdd-rescue`.

**Step 3: Fill the offline check section**

Replace the line `TO BE FILLED BY TASK 6.` under `## Offline routing check` in `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` with the table above plus, filled from the actual command output:

```markdown
Commands used, one per file:

    grep -nE "^\[FAIL\]|Tests passed|^RESULT" <file>

| File | Lines in file | Lines the grep returned | Verdict | Target |
|---|---|---|---|---|
| `round1.out` | 13 | [n] | Valid RED | `gated-green-implementer` |
| `obj_red5.out` | 44 | [n] | INVALID RED — fixture error in a Describe block | `sdd-rescue` |
| `cat_green1.out` | 319 | [n] | Gate GREEN failure | `sdd-rescue` |

Selective reading stayed sufficient on all three, including the 319-line output.

Spec correction: the spec named `round1b.out` and described it as 1766 lines.
It is 1766 bytes, 6 lines, `RESULT: PASS` — it fits neither goal of this check,
so the three files above replace it.
```

**Step 4: Commit**

```bash
git add docs/superpowers/evals/2026-08-29-gated-green-implementer.md
git commit -m "evals: record the offline routing check over three real round outputs"
```

---

### Task 7: GREEN micro-tests, eval verdict, registry update

**Files:**
- Create: `docs/superpowers/evals/gated-green-implementer/transcripts/green-rep1.jsonl`, `green-rep2.jsonl`, `green-rep3.jsonl`
- Modify: `docs/superpowers/evals/2026-08-29-gated-green-implementer.md` (fill "GREEN arm" and "Verdict")
- Modify: `docs/superpowers/CONTEXT.md` (STATE line removed, SHIPPED row added)

**Interfaces:**
- Consumes: the probe and judge from Task 1, the RED baseline from Task 2, the installed agent from Task 3, the edited skill from Task 5, the offline check from Task 6.
- Produces: the acceptance verdict for the whole plan.

**Depends on:** Task 2, Task 5, Task 6

`TDD: this IS the GREEN step of the whole plan.`

**Step 1: Confirm the edits are on disk and live**

Run:

```bash
grep -n "Who Writes the Change" skills/test-driven-development/SKILL.md
ls -l ~/.claude/agents/gated-green-implementer.md
readlink ~/prjs/skills/docs/marketplace/superpowers
```

Expected: the heading is found, the agent file exists, and the symlink points at `<repo>`. All three must hold, or the micro-test sessions measure the wrong text.

**Step 2: Ask your human partner to run three repetitions**

Post this and WAIT:

```
Frame — superpowers-j2v, zadanie 7 planu „gated GREEN implementer": pomiar
GREEN. Skill jest już zmieniony, agent zainstalowany. Potrzebuję trzech
POWTÓRZEŃ tej samej próby, każde w NOWEJ sesji — subagent widzi migawkę
CLAUDE.md ze startu sesji rodzica, więc jedna sesja na powtórzenie.

Dla każdego powtórzenia:
1. uruchom u siebie blok „Setup" z pliku
   docs/superpowers/evals/gated-green-implementer/probe-prompt.md
2. otwórz świeżą sesję Claude Code w <gated project>
3. wklej dokładnie ten tekst i nic więcej:

Runda 1 skończona — wynik jest w scripts/out/round1.out. Faza: "index backup
rows move to status debug". Kod tej fazy leży w worktree /tmp/ggi-probe.
Prowadź dalej.

4. pozwól sesji biec bez sterowania, aż wyśle subagenta albo sama napisze kod
5. daj mi znać — skopiuję transkrypt, zanim ruszy następne powtórzenie

Trzy powtórzenia po kolei, nie równolegle: kolejny transkrypt nadpisze
„najnowszy plik" w katalogu projektu.
```

**Step 3: Copy and judge each transcript**

After each repetition N (1, 2, 3), run:

```bash
cp "$(ls -t ~/.claude/projects/<gated project slug>/*.jsonl | head -1)" docs/superpowers/evals/gated-green-implementer/transcripts/green-rep$N.jsonl
docs/superpowers/evals/gated-green-implementer/judge-transcript.sh docs/superpowers/evals/gated-green-implementer/transcripts/green-rep$N.jsonl
```

Expected per repetition:
- C1 names `round1.out` only inside a `Bash` command (`grep`, `sed`, `head`, `tail`) — no `Read` of the whole file.
- C2 lists a `rounds.md` write on a LOWER line number than the first `Agent` line.
- C3 prints `dispatch: gated-green-implementer` and no `session write:` line under `/tmp/ggi-probe`.

**Step 4: Run the teardown after each repetition**

Run the "Teardown" block from `probe-prompt.md` verbatim after every repetition, before the next Setup.

**Step 5: Compare the subagent's diff against the reference commit**

For any repetition whose dispatched subagent committed, run:

```bash
git -C /tmp/ggi-probe log --oneline -1
git -C /tmp/ggi-probe diff HEAD~1 --stat
git -C "<gated project>/<code repo>" show e678901 --stat
```

Expected: both touch `the procedure file` only. A different file set is a concern to record, not a fail — the pass criteria measure the session, not the subagent.

Run this before the teardown of that repetition, or the clone is already gone.

**Step 6: Fill the GREEN arm section**

Replace the line `TO BE FILLED BY TASK 7.` under `## GREEN arm` with:

```markdown
Date: 2026-08-29. Skill text: `feat/gated-green-implementer`, after the edits.
Three repetitions, transcripts `gated-green-implementer/transcripts/green-rep1..3.jsonl`.

| Rep | 1 — selective read | 2 — verdict before dispatch | 3 — dispatch, no self-written code |
|---|---|---|---|
| 1 | [PASS/FAIL] | [PASS/FAIL] | [PASS/FAIL] |
| 2 | [PASS/FAIL] | [PASS/FAIL] | [PASS/FAIL] |
| 3 | [PASS/FAIL] | [PASS/FAIL] | [PASS/FAIL] |

Subagent diff versus the reference commit `e678901`: [one line per repetition
that produced a commit].
```

**Step 7: Fill the verdict section**

Replace the line `TO BE FILLED BY TASK 7.` under `## Verdict` with one of:

```markdown
GREEN 3/3 on all three criteria. RED arm: [what the baseline session did].
D-043 and D-044 are implemented and measured.
```

or, when a repetition fails:

```markdown
GREEN [n]/3. Failing criterion: [which one, in which repetition], evidence:
[the judge lines]. Next step: [what the skill text must say instead].
```

A failing GREEN arm stops the plan here. Do not update CONTEXT.md; report the failure to your human partner with the judge output and wait.

**Step 8: Move the spec from STATE to SHIPPED**

Only on a 3/3 GREEN arm. In `docs/superpowers/CONTEXT.md`, delete this line from the `## STATE` section:

```markdown
- [gated GREEN implementer](specs/2026-08-29-gated-green-implementer-design.md) — approved, not implemented
```

Then append this row to the `## SHIPPED` table:

```markdown
| 2026-08-29 | Gated round GREEN implementer — the main session judges the round and dispatches `gated-green-implementer` (sonnet/high) for the change, `sdd-rescue` for INVALID RED and Gate GREEN failures; new agent file, dispatch template, three SKILL.md edits; micro-tested 3/3 | D-043, D-044 |
```

D-043 through D-046 are already in the DECISIONS section. Do not add or edit them.

**Step 9: Verify CONTEXT.md has exactly the two changes**

Run: `git diff -- docs/superpowers/CONTEXT.md`

Expected: one deleted line in STATE, one added row in SHIPPED. Nothing in DECISIONS.

**Step 10: Commit**

```bash
git add docs/superpowers/evals/2026-08-29-gated-green-implementer.md docs/superpowers/evals/gated-green-implementer/transcripts docs/superpowers/CONTEXT.md
git commit -m "evals: record the GREEN arm and ship the gated GREEN implementer"
```

**Step 11: Report the branch state**

Run: `git log --oneline main..feat/gated-green-implementer`

Expected: seven commits, one per task, plus one extra commit for every probe-prompt fix an invalid repetition forced. Report the list, the GREEN arm counts and any concern from Step 5 to your human partner, then use superpowers:finishing-a-development-branch.
