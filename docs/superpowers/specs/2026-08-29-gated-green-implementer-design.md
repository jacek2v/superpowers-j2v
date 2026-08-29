# Gated round GREEN implementer

Date: 2026-08-29
Status: approved, not implemented

## Problem

In Gated Testing Mode the main session does everything at a gate. It reads the
round output, judges the verdict, and writes the GREEN change itself. The
session model is Opus, so implementation work runs on the most expensive and
slowest model in the toolchain.

Two skills already avoid this. `subagent-driven-development` and its parallel
copy dispatch a `general-purpose` implementer with `model: sonnet` for all
implementation tasks (`subagent-driven-development/SKILL.md:113`). A gated
session that runs without either skill gets no such dispatch.

`executing-plans` is the no-subagent fallback and is out of scope. Its
description names the condition: "subagent dispatch is unavailable".

Measurement, 2026-08-29. A Sonnet subagent reproduced an Opus session's GREEN
commit from the same round output. The diff was identical except one comment
line. The subagent used 55.6 k tokens against 1.24 M cache-read tokens in the
Opus session. Full record: the skills
workspace docs repository, file
`docs/superpowers/analyses/2026-08-29-cc-model-effort-usage-analysis.md`. That
file sits in a different repository, so no link resolves from here.

## Goal and honest limits

The goal is speed, not token price. The measured gain is not a faster single
round. A one-line fix gets no speedup, because dispatch overhead replaces the
time Opus spent writing one line.

The real gain is cumulative. Every request re-sends the whole conversation, so
file reads and diffs from implementation work stay in the main context and every
later Opus turn pays for them. A subagent starts with a fresh context and
returns only a report, so the main context stops growing with implementation
work. The gain also grows with the size of the change.

## Scope

The rule applies to a gated session that has no SDD orchestration. When
`subagent-driven-development` or `subagent-driven-development-parallel` runs the
phase, its own phase orchestration governs and this rule does not apply.

## Flow at a gate

| Step | Actor | Action |
|---|---|---|
| 1 | main session | Post the round request. Arm the watch. Wait. |
| 2 | main session | Read the round output selectively. Take the result line, the counts, and the failure blocks. |
| 3 | main session | Judge the verdict. Append it to the round ledger `.superpowers/rounds.md`. |
| 4 | main session | Dispatch the subagent that the verdict selects. |
| 5 | subagent | Write the change in the given worktree. Commit. Report. |
| 6 | main session | Inspect `git log -1` and the diff. Then request the next round. |

Step 2 stays in the main session. The interesting lines are a handful, and an
extra dispatch adds start-up delay before every gate without a matching gain.

## Dispatch routing

| Verdict | Dispatch target | Model / effort | Reason |
|---|---|---|---|
| Valid RED | `gated-green-implementer` | sonnet / high | The missing behavior is known. This is implementer work. |
| INVALID RED | `sdd-rescue` | opus / high | The tests are wrong. Tests state the required behavior. |
| Gate GREEN failure | `sdd-rescue` | opus / high | The cause is unknown. A bad fix forces another round. |

When `sdd-rescue` is missing from the agent registry, dispatch
`general-purpose` with the session model. This fallback follows D-035.

A BLOCKED report from `gated-green-implementer` escalates to `sdd-rescue`. One
jump, not an effort ladder. This follows the BLOCKED escalation in
`subagent-driven-development/SKILL.md:125`.

## What stays with the main session

Three things never move to a subagent. The round verdict. The round ledger
entry. The conversation with the operator.

This keeps D-009 intact, because the main agent still owns the gate. It also
keeps D-005 intact, because implementation starts only after the main session
confirms a valid RED.

A subagent commit invalidates the round output that produced it, per D-010. The
main session requests a new round. A subagent report never closes a task.

## Files

| File | Change | Content |
|---|---|---|
| `deploy/agents/gated-green-implementer.md` | new | Frontmatter `model: sonnet`, `effort: high`. Body passes control to the dispatch prompt. |
| `deploy/agents/README.md` | edit | One table row. The new file name in the copy command. |
| `skills/test-driven-development/gated-round-dispatch.md` | new | The dispatch prompt template. |
| `skills/test-driven-development/SKILL.md` | edit | New subsection in "Gated Testing Mode". Reworded "Valid RED". One new rationalization row. |
| `docs/superpowers/CONTEXT.md` | edit | D-043 and D-044. |

The agent file body carries no role instructions. `sdd-reviewer` and
`sdd-rescue` are bare passthroughs for the same reason
(`subagent-driven-development/SKILL.md:308`): the agent carries model and
effort, and the template stays the only source of instructions.

## Dispatch template content

The main session fills the template. It passes no path to the plan and no path
to the spec. When a plan exists, the session pastes the one relevant task block
into the prompt. This follows the construction rule in
`subagent-driven-development/SKILL.md:9`.

One template serves all three dispatch targets. The verdict field and the
wanted-behavior field change. The `sdd-rescue` dispatches for INVALID RED and
for a Gate GREEN failure use the same template.

The template carries:

- the worktree path
- the verdict the main session issued
- the verbatim failure blocks from the round output
- the wanted behavior, written by the main session
- the ban on editing test files
- the commit instruction, RED first and GREEN second
- the report format: files changed, diff summary, commit subject

## SKILL.md edits

The new subsection sits in "Gated Testing Mode" and holds the routing table and
the SDD carve-out clause. The "Valid RED" section changes from "you judge and
proceed" to "you judge, then you dispatch".

New rationalization row:

| Excuse | Reality |
|--------|---------|
| "It is one line — dispatching a subagent is slower than typing it" | The session judges the round. The subagent writes the code. Implementation work in the main context is paid for by every later turn. |

## Acceptance

Three micro-tests. Each runs in a fresh session started in
`~/prjs/<gated project>`. That project is the only one with a
`## Gated testing` block and real round files. A fresh session per repetition is
required, because a subagent sees the CLAUDE.md snapshot from the parent session
start.

Input: a simulated notification for a finished `scripts/out/round1.out` from
2026-08-21, which shows 19 passed and 1 failed.

A pass needs all three:

1. The session reads the round output selectively. It does not read the whole file.
2. The session issues the verdict and appends it to the round ledger before it dispatches.
3. The session dispatches `gated-green-implementer` and writes no code itself.

A fail: the session writes the change itself, or it dispatches before the verdict.

The session writes nothing in that project, except the subagent commit in a
throwaway worktree.

Offline check, no live session: dispatch on `scripts/out/round1b.out` from
2026-08-18, which holds 1766 lines. It checks two things. Selective reading
must stay sufficient on a large file. The INVALID path must go to `sdd-rescue`.

## Decisions

- **D-043** — In gated sessions without SDD orchestration the main session
  judges the round and dispatches a sonnet/high implementer for the GREEN
  change. INVALID RED and Gate GREEN failures go to `sdd-rescue`.
- **D-044** — Agent files carry model and effort only. The name states the role.
  Role instructions live in the dispatch template.

## Approaches considered

**A subagent that waits for the round.** The main session dispatches a subagent.
The subagent arms a watch, waits for the output file, analyzes it, and reports.
Measured on 2026-08-29 and rejected: the subagent armed the watch, then ended
after 15 seconds with a report that said it was waiting. The flag file appeared
15 seconds later. No second notification arrived in the next 65 seconds. A
subagent ends when it stops calling tools, so only the main session can wait.

**One dispatch that judges and fixes.** The subagent judges the round and writes
the GREEN change in the same dispatch. Rejected: the code appears before the
main session confirms a valid RED, which breaks D-005. To avoid that, the
subagent would have to own the verdict, which breaks D-009.

**A relay subagent for the round output.** A small subagent returns the verbatim
lines and the main session judges them. Rejected: the wanted lines are a
handful, and the extra dispatch adds delay before every gate.

**One sonnet agent for every round verdict.** The same agent handles the GREEN
change, the INVALID RED test repair, and the Gate GREEN failure. Rejected: it
needs a change to D-039 and it splits from the SDD routing, where repairs stay
on Opus.

**No agent file, `general-purpose` plus `model: sonnet`.** Rejected by the
operator: effort would follow the session instead of staying fixed.

**Generic effort agents, `subagent-high` and `subagent-medium`.** The operator
proposed replacing the named agents with effort carriers and passing the model
per call. The dispatch tool supports it, because the call-level `model`
overrides the agent frontmatter. Rejected by the operator as unnecessary. The change also touches five skills,
two prompt templates, and D-035, whose wording was eval-validated 5/5.

**A size threshold for the dispatch.** Dispatch only above a file count or a
failure count. Rejected: the threshold has no data behind it, and the session
does not know in advance how many files the change touches.

## Out of scope

- No change is needed in `~/prjs/<gated project>/CLAUDE.md`. The handoff asked
  to redirect line 33, which says "you read the result from
  `scripts/out/round3.out`". That request assumed a subagent reads the round
  output. The approved flow keeps that read in the main session, so the line
  already describes the wanted behavior. The dispatch rule stays in the skill,
  and D-003 allows only `Runner:` and `Local subset:` as project overrides.
