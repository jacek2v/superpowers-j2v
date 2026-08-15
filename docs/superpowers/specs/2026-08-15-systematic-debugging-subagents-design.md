# Systematic Debugging: Subagent Delegation — Design

**Date:** 2026-08-15
**Status:** Approved
**Goal:** Stop main-session context growth during debugging. Subagents read the evidence. The main agent receives short syntheses.

## Problem

The current skill makes the main agent read logs, stack traces, test output, and source files. Every read stays in the main context until the session ends. Long debugging sessions exhaust the context window.

## Decision Summary

- Modify `skills/systematic-debugging` in place. Do not create a variant skill.
- Delegate all four phases to subagents, with mitigations listed below.
- Delegation is unconditional. There is no "simple bug" exception.
- Phase 1 dispatches 2–4 investigators in parallel, one investigation path each.
- Model choice follows work character, not cost. Simple relay work gets sonnet. Reasoning work gets the session model.

## Roles and Models

| Role | Agent type | Model | Task character |
|---|---|---|---|
| Investigator: errors, reproduction, recent changes (Phase 1) | `Explore` | sonnet | Simple: read and report with evidence |
| Investigator: data-flow tracing (Phase 1) | `Explore` | session model | Reasoning across the call stack |
| Pattern analyst (Phase 2) | `Explore` | session model | Reasoning: find the significant difference |
| Experimenter (Phase 3) | `general-purpose` | sonnet | Run one prescribed experiment, report verbatim output |
| Fixer (Phase 4) | `general-purpose` | session model | Reasoning: write the test and the fix |
| Rescue (escalation) | `sdd-rescue` | opus (from agent definition) | Retry after fixer failures |

Rationale for sonnet on simple work: it is faster and hallucinates less than larger models on relay tasks (operator decision, 2026-08-15).

## What Stays in the Main Session

The main agent alone owns:

- Hypothesis formation.
- The attempt ledger.
- The 3-failure counter and the architecture question.
- The final full-suite verification run.
- Every conversation with the human partner.

Subagents never decide and never gate. This preserves D-009, D-017, and D-031.

## Debugging Loop

1. **Dispatch Phase 1.** Send 2–4 `Explore` investigators in one message. Each prompt contains the symptom, one investigation path, and the return format: a synthesis of 15 lines maximum plus raw evidence (exact command and verbatim error lines).
2. **Synthesize.** The main agent merges reports into root-cause candidates. If a path returns "nothing suspicious", the main agent judges whether that is absence of a trace or a miss. It may re-dispatch that path with a sharper prompt.
3. **Phase 2, conditional.** Dispatch the pattern analyst only when a working counterpart of the broken code exists.
4. **Hypothesis and ledger.** The main agent states one hypothesis and records it in the attempt ledger: hypothesis, experiment, result, short rationale. The ledger lives in the main agent's messages, so it survives context compaction (pattern of D-011).
5. **Experiment.** The experimenter receives one exact command or one minimal change. It returns verbatim output, a verdict (confirmed or refuted), and a short rationale. It reverts its temporary instrumentation before finishing. A refuted hypothesis goes into the ledger, then the main agent forms a new one.
6. **Fix.** The fixer receives the root-cause synthesis, the TDD requirement (failing test first), the exact test command, and the expected outcome. It returns verbatim test output. On failure it returns what it tried and a short failure rationale with raw evidence.
7. **Failure ladder.** First fixer failure: re-dispatch with ledger conclusions. Second failure: dispatch `sdd-rescue`. Third failure: STOP. The main agent questions the architecture and talks to the human partner. The existing "3+ fixes" rule is unchanged.
8. **Final verification.** The main agent runs the full test suite itself, once, before it claims success. A subagent's "tests pass" is self-report and does not satisfy verification-before-completion.

## Gated Testing Interaction

In projects that declare `## Gated testing`, subagents do not run tests. Test commands go through operator gates as before (D-009). Delegation then covers investigation and code writing. Test results return through operator rounds.

## Risk Mitigations for Full Delegation

| Risk | Mitigation |
|---|---|
| Failure counter dies with each subagent | Attempt ledger in the main session feeds every dispatch |
| Failure rationale is self-report | Subagents must return raw evidence: exact command plus verbatim error lines |
| "Tests pass" is self-report | Main agent prescribes the exact test command and re-runs the full suite itself once |
| Fixer lacks investigation nuance | Fixer prompt carries the root-cause synthesis from the ledger |
| Dead-end subagent finishes a bad fix instead of escalating | Ladder and human-partner escalation live only in the main session |
| Weak model misses the key difference | Reasoning paths (data-flow, pattern analysis) get the session model from round one |

## File Changes

**`skills/systematic-debugging/SKILL.md`** — additive only. Phases, Red Flags table, and rationalization table keep their tested wording.

| Location | Addition |
|---|---|
| After "The Iron Law" | Second rule: subagents read the evidence. The main agent does not open logs, stack traces, or source files itself. Dispatch is unconditional. |
| Phase 1 | Dispatch instruction for 2–4 `Explore` investigators, path→model table, return format |
| Phase 2 | Conditional dispatch of the pattern analyst (session model) |
| Phase 3 | Attempt ledger plus experimenter dispatch (sonnet). Hypotheses stay in the main session. |
| Phase 4 | Fixer dispatch (session model), failure ladder with `sdd-rescue`, final verification by the main agent |
| Red Flags | New entries: "I'll just take a quick look at this log myself", "Dispatch is too much overhead for this bug" |
| End | Gated-testing note |

**New reference file `skills/systematic-debugging/debugging-subagents.md`** — prompt templates (investigator, analyst, experimenter, fixer), return formats, role/model table. Pattern of D-033: mechanics in the reference file. SKILL.md keeps only the rules that must always be in context: unconditional dispatch, the ledger, the ladder.

**Frontmatter `description`** — unchanged. Triggering is tested.

## Validation

The repo requires eval evidence for skill changes. After implementation, run through superpowers:writing-skills:

- RED probe on the old text: does the agent read logs itself?
- GREEN probe on the new text: does it dispatch, does the ledger appear, does it run the final verification itself?
- Compare old and new text on the same day (same-day A/B control).

## Rejected Directions

- Separate variant skill (like subagent-driven-development-parallel): two copies to synchronize, no fallback need here.
- "Simple bug" exception to delegation: reopens the "this bug is simple" rationalization the skill exists to block.
- Full rewrite around an orchestration loop: discards tested wording, forces evals to cover everything from zero.
- Sonnet for all Phase 1–2 paths: leaves the false-negative risk in data-flow tracing open.
