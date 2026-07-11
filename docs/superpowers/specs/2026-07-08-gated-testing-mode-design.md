# Gated Testing Mode — Design (superpowers-j2v)

**Date:** 2026-07-08
**Status:** Approved in brainstorming; awaiting implementation plan
**Scope:** `superpowers-j2v.git` — 6 skill files + 2 prompt templates; example rollout in `<gated project>/CLAUDE.md`; optional clause in `~/.claude/CLAUDE.md`

## Problem

In projects where (some or all) tests can only be executed on an external system CC cannot reach — example: `<gated project>`, where pytest runs on <host>/DWH02, the operator copies changed files via robocopy, runs a pasted single-line PowerShell command, and pastes the output back into chat — the superpowers TDD loop breaks down. Observed failure: CC writes RED and GREEN back-to-back with no verification in between.

Per-test operator gating would be unworkable (dozens of interruptions per plan). Requirement: batch RED verification and GREEN verification so the operator is needed ~2× per group of tasks.

## Root cause — why RED and GREEN currently merge

| Layer | Instruction | Effect when CC cannot run tests |
|---|---|---|
| `test-driven-development` | "Verify RED/GREEN — MANDATORY", assumes CC runs the test itself | Step is unexecutable → CC improvises: writes test + implementation in one go |
| Project CLAUDE.md (<gated project>, old line) | "Each TDD step lands as two separate commits: RED, GREEN" — a commit rule, not a stop rule | Reads as "commit RED, then immediately commit GREEN" — legitimizes merging the phases |
| `subagent-driven-development` | "Continuous execution: do not pause between tasks"; implementer "implements, tests, commits"; Verification Contract demands test output in the implementer report | Actively forbids the operator pause; the required evidence cannot exist |
| `writing-plans` | Emits per-task "Run: pytest… Expected: FAIL/PASS" steps | Plans contain physically unexecutable steps → silently skipped |
| `verification-before-completion` | "No completion claims without fresh verification" | No concept of operator-provided evidence → deadlock or false claims |
| `~/.claude/CLAUDE.md` | "Always follow strict TDD (RED-GREEN-REFACTOR)" | Reinforces the per-test cycle; no sanctioned batched variant |

## Solution overview

A **Gated Testing mode** woven into the existing skills (no new skill — decided by the human partner), explicitly activated per project, defaulting to classic behavior when absent. Batching is a property of the mode, not of operator availability: when CC itself has access to the test system, the same batched flow applies and CC executes the rounds itself.

### Activation

- The literal heading `## Gated testing` in the project CLAUDE.md activates the mode. Optional override lines beneath it:
  - `Runner: claude` — CC executes rounds itself (it has access to the test system). Default: `operator`.
  - `Local subset: <command/filter>` — tests CC can run locally, handled in the classic per-test micro-cycle. Default: none (all tests gated).
- In-session activation: the human declares it (e.g. "I run the tests on X myself"); CC confirms the parameters and offers to persist the block in CLAUDE.md.
- Everything else is fixed in the skills — no other configuration.
- **No declaration → all skills behave exactly as today (zero behavior change).**
- **Anti-improvisation rule** (added to `test-driven-development`): if CC cannot execute a test and no gated-testing declaration exists → STOP and ask the human partner. Never write implementation on top of an unverified RED.

### Batch cycle (per plan phase)

The unit is a **phase**: 2–5 related tasks, grouped by `writing-plans`, with gate steps written explicitly into the plan.

1. Write all gated tests for the phase's tasks (RED commit per task) → **Gate RED**
2. Implement all the phase's tasks (GREEN commit per task; local-subset tests verified continuously in the classic micro-cycle) → **Gate GREEN**
3. Refactor → next phase.

A phase with no gated tests gets no gate steps. Interfaces between tasks come from the plan (writing-plans' Interfaces block), so tests for later tasks can be written before earlier tasks are implemented.

### Round request format

Produced by CC at each gate; with `Runner: claude` CC executes the command itself instead of asking.

```
ROUND <n> — RED|GREEN, phase "<name>"
Source:  <worktree root>
Files:   <relative paths of files to copy>
Command: <single short one-line command>
Expected: <e.g. "8 failed, 0 errors — all new tests">
```

- Response: full command output (operator paste, or CC's own run).
- Commands use output-friendly flags (e.g. `pytest -q --tb=short`) to keep pastes small.
- **RED rounds run only the phase's new tests. GREEN rounds run the full suite, no filter** (maximal regression coverage; on the test system the local subset runs there too).
- Round counter `<n>` is global within the feature branch; every round and its verdict is recorded in the progress ledger (survives context compaction).

### Valid RED criteria

Each new test must fail attributably to the missing feature: an assertion failure or a clean "object/module does not exist" error. A test-file syntax error, fixture error, or connection error makes the RED invalid → fix the tests → **re-round narrowed to the affected files**. Same for GREEN: failures → fix code (never the test to make it pass) → narrowed or full GREEN re-round.

### Refactor policy

Refactor only after the phase's GREEN gate. The local subset protects immediately; gated regressions surface at the next phase's GREEN round; the final phase is covered by the closing full-suite round in `finishing-a-development-branch`.

### Commit discipline (gated mode only)

Per task: RED commit(s) first, then GREEN commit(s), never mixed — ordered RED-first GREEN-second within the phase so git log mirrors the round structure. This moves from project CLAUDE.md into the skill. Classic mode commit style is unchanged.

### Evidence rules

Round output is fresh verification evidence **only for the code state the round was generated for**; any later edit invalidates it. Claims are limited to what the output actually shows. This becomes a recognized evidence class in `verification-before-completion`.

## Changes per file (`superpowers-j2v.git/skills/`)

Each file gains one self-contained block, to keep upstream merge conflicts trivial.

| File | Change |
|---|---|
| `test-driven-development/SKILL.md` | New section **"Gated Testing Mode"**: activation, defaults, batch cycle, valid-RED criteria, re-rounds, commit discipline, anti-improvisation rule, Iron Law variant: *no implementation for a task before the phase RED gate confirms its tests fail correctly* |
| `writing-plans/SKILL.md` | When the mode is declared: group tasks into phases (2–5 related tasks); write explicit **Gate RED / Gate GREEN steps** into the plan with file list, single-line command, and expected result; phase test-writing steps precede the RED gate, implementation steps follow it; local-subset steps keep classic inline run steps |
| `executing-plans/SKILL.md` | At a gate step: STOP → emit the standard round request → wait for output (`Runner: claude`: execute it yourself) → analyze → fix re-rounds as needed; never proceed past a gate without valid evidence |
| `subagent-driven-development/SKILL.md` | Carve-out in Continuous Execution: gates are legitimate stops, handled by the main agent (subagents never interact with the operator). Phase orchestration: test-writer subagent writes the phase's tests (runs only the local subset itself) → main agent runs Gate RED → implementer subagent per task → main agent runs Gate GREEN. Verification Contract: for gated tests the evidence is the round output held by the main agent (logged in the ledger); implementers name which gated tests cover their change instead of pasting their output |
| `subagent-driven-development/implementer-prompt.md`, `task-reviewer-prompt.md` | One-line adjustments: implementer must not attempt gated tests; reviewer must not demand gated-test output from the implementer report |
| `verification-before-completion/SKILL.md` | New evidence class: gated-round output (operator paste or CC-run), fresh only for the exact code state the round was generated for |
| `finishing-a-development-branch/SKILL.md` | Step 1 "Verify Tests": in gated mode the fresh full-suite verification = one final round (per declared runner) |

## CLAUDE.md changes

### `<gated project>/CLAUDE.md` (example rollout)

Replace the line "I'll run the tests on the <host>/DWH02 server myself. Each TDD step lands as two separate commits: …" with:

```markdown
## Gated testing
- Local subset: uv run pytest -m "not integration" — CC runs these itself
```

**Verify before rollout** (plan task): the actual pytest marker/filter that separates DB-free tests in `<code repo>` — `-m "not integration"` is a placeholder for whatever the real convention is. The neighboring lines about single-line PowerShell commands and sqlcmd/SSMS compatibility stay unchanged (general formatting rules, not part of the mode).

### `~/.claude/CLAUDE.md` (optional, recommended)

Append to the strict-TDD bullet: "In projects declaring `## Gated testing`, the batched gated variant defined by the skills applies."

## Requirements

- R-1: With no `## Gated testing` declaration, all modified skills behave exactly as before (zero regression).
- R-2: Activation is explicit only: CLAUDE.md heading or in-session declaration (which CC offers to persist). CC never silently enters the mode.
- R-3: Defaults fixed in the skills: runner = operator, all tests gated. Only `Runner:` and `Local subset:` are declarable overrides.
- R-4: Phase cycle: all phase gated tests (RED commits per task) → Gate RED → all phase implementations (GREEN commits per task) → Gate GREEN → refactor.
- R-5: No implementation code for a task before the phase RED gate confirms its tests fail for the right reason.
- R-6: Standard round request: source root, file list, single short one-line command, expected outcome.
- R-7: Valid-RED analysis per test; invalid RED → fix → re-round narrowed to affected files.
- R-8: Gate GREEN runs the full suite (no filter); failures → code fix → GREEN re-round; phase ends only green.
- R-9: Gates are legitimate stops in both executors; only the main agent handles gates (never subagents).
- R-10: Round output is valid evidence only for the code state it was generated for.
- R-11: Every round and verdict is recorded in the progress ledger.
- R-12: In gated mode, `finishing-a-development-branch` performs its final full-suite verification as one final round.

## Validation

- Skill edits follow `superpowers:writing-skills` discipline (behavioral content).
- Toy-project scenario with the declaration present and a faked operator: assert (a) no implementation before Gate RED, (b) round request format, (c) narrowed re-round on an invalid RED, (d) zero behavior change without the declaration.
- Real-world trial: next feature in `<gated project>`.

## Alternatives considered

- **A. New dedicated skill + one-line hooks in existing skills** — smallest upstream-merge surface, single source of truth; rejected by the human partner in favor of keeping the mode where readers already are.
- **C. Project CLAUDE.md protocol only, fork untouched** — rejected: project instructions would fight the skills' MANDATORY/continuous-execution language every session (today's exact failure mode), and plans would still contain unexecutable steps.

## Risks and trade-offs

- **Upstream sync:** six synced files gain one block each — larger merge-conflict surface, consciously accepted; mitigation: keep each change one self-contained block.
- **Batched RED** weakens per-test fail-first granularity — accepted; mitigated by per-test analysis of round output against the valid-RED criteria.
- **Paste size** on large suites — mitigated by `-q --tb=short` flags and narrowed re-rounds.
