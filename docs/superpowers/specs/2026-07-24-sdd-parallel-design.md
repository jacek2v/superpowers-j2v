# SDD-Parallel Design — parallel subagent-driven development

**Date:** 2026-07-24
**Status:** Approved design, pending implementation plan

## Goal

Maximize wall-clock speed of plan execution by running independent tasks concurrently, without lowering the quality bar of subagent-driven-development (SDD). Higher token spend is an accepted trade-off. The sequential SDD skill stays untouched and fully functional.

## Decision Summary

- New skill `subagent-driven-development-parallel` is a **full copy** of `subagent-driven-development` adapted for parallel orchestration (approved variant: full copy, not a delta-by-reference). The old skill stays byte-identical — sequential fallback for tightly-coupled plans, eval baseline, upstream-mergeable.
- The parallel skill is the **default entry point**, delivered by routing, not hierarchy: writing-plans' Execution Handoff and the generated plan header name it first. The old skill knows nothing about the new one.
- Task dependencies are declared at **plan time**: writing-plans emits a mandatory `Depends on:` line per task. No runtime dependency inference.
- Unit of parallelism = task. Inside a task the TDD cycle stays sequential.
- Conscious deviation from the fork's explicit-activation pattern (spirit of D-001/D-002): the new default changes executor behavior without a per-project declaration. Recorded as its own decision; the escape hatch is invoking the sequential skill explicitly.

## Component 1: skill `subagent-driven-development-parallel`

Full copy of `skills/subagent-driven-development/` (SKILL.md, implementer-prompt.md, task-reviewer-prompt.md, scripts/) with the following adaptations. Everything not listed here is copied unchanged.

### Frontmatter

- `name: subagent-driven-development-parallel`
- `description`: triggering conditions only, per writing-skills SDO — no workflow summary. Working draft: "Use when executing implementation plans in the current session and the plan's tasks carry Depends on: lines". Final wording fixed during implementation via description micro-tests (must discriminate cleanly against the old skill's description).

### Scheduling (replaces the sequential per-task loop)

- **Pre-flight additions:** build the dependency DAG from `Depends on:` lines; validate it is acyclic and consistent with Interfaces blocks (every Consumes produced by a declared dependency); validate `Files:` disjointness of tasks that may run concurrently. Findings join the existing one-batched-question pre-flight protocol.
- **Task states:** `pending → ready → implementing → reviewing → fixing → merged`. A task is *ready* when ALL its dependencies are **merged** — not merely review-clean — because the dependent implementer needs the produced interfaces present in its branch base.
- **Event-driven ready-set scheduling, no wave barriers:** dispatch every ready task's implementer immediately (one message, multiple dispatches — they run concurrently, in the background); on each completion notification advance that task's pipeline one step and recompute the ready set. A slow task never blocks independent DAG branches.
- **Legacy plans** (no `Depends on:` lines): fall back to sequential order (task N depends on task N−1) and offer the human partner a one-time plan annotation instead.

### Worktree-per-task protocol

- Controller creates the integration worktree once (superpowers:using-git-worktrees, as today) with integration branch `B`.
- Per task `T`: controller creates branch `task/T` from the current tip of `B` plus a dedicated worktree via `git worktree add`; the dispatch prompt names the worktree path. Implementer, fix subagents, and re-reviews for `T` all operate on that same path. Harness-native per-dispatch worktree isolation is deliberately NOT used — the worktree must persist across the implementer → reviewer → fixer chain.
- The review pipeline per task is unchanged (report file → review package from the task branch range, BASE = branch point → task reviewer → fix subagent → re-review); it simply runs concurrently across tasks.
- **Merge is controller-owned and serialized:** after a clean review, merge `task/T` into `B`. On conflict, dispatch a fix subagent to rebase `task/T` onto `B` and resolve; a rebase invalidates the prior verdict (cf. D-010) — re-review the post-rebase diff before merging. After merge: remove worktree and branch, append the ledger line, recompute the ready set.

### Ledger schema (extended)

`.superpowers/sdd/progress.md` stays the compaction-recovery map. A task's entry additionally records: current state, branch name, worktree path, commit range, review verdicts. Tasks recorded as merged are never re-dispatched; after compaction, trust ledger + `git log`/`git worktree list` to reconstruct scheduler state.

### Sequential invariants (the quality bar — unchanged)

- Per-task two-verdict review (spec compliance + code quality) and re-review loops.
- Merges, ledger writes, gates: controller only (D-009).
- Gated Testing Mode: phase cycle preserved (D-004) — one test-writer per phase, Gate RED, then the phase's implementers run in parallel per this skill, Gate GREEN full-suite as today.
- Final whole-branch review over `B` after all tasks merged; then project-registry op 5; then finishing-a-development-branch with its full-suite verification (D-012).
- Model routing unchanged: implementer = `general-purpose` + `model: sonnet`; task and final reviewers = `sdd-high`; fixer and BLOCKED escalation = `sdd-escalate`.

### Red Flags (delta vs the old skill)

- REMOVED: "Dispatch multiple implementation subagents in parallel (conflicts)".
- ADDED: never two subagents concurrently in one worktree; never dispatch a task whose dependencies are not merged; never merge a branch state that was not itself review-approved (rebase ⇒ re-review); never delegate a merge or a gate to a subagent; never run concurrent tasks with overlapping `Files:` blocks.

## Component 2: writing-plans changes

- Task template gains a mandatory line after **Interfaces:**: `**Depends on:** Task N, Task M` or `**Depends on:** none` — derived from Interfaces (Consumes ⊆ union of the dependencies' Produces).
- Guidance: prefer decompositions that minimize dependency chains — a short critical path maximizes parallel execution.
- Self-review gains one check: DAG acyclic; every Consumes covered by a declared dependency; no two mutually independent tasks share files.
- Plan header boilerplate and Execution Handoff: name `subagent-driven-development-parallel` as the recommended default; sequential `subagent-driven-development` and `executing-plans` remain listed alternatives.

## Component 3: testing (writing-skills RED-GREEN-REFACTOR)

Per superpowers:writing-skills (Iron Law: no skill change without a failing test first) and repo policy (eval evidence for skill changes):

- **RED:** baseline scenarios without the new skill — a controller holding a `Depends on:`-annotated plan. Expected failures to document verbatim: purely sequential execution (speed failure), or naive parallelism (same-worktree dispatch, merging without review, dispatching dependents early — quality failures).
- **GREEN:** write the skill as specced; re-run the scenarios; verify parallel dispatch happens AND the invariants hold.
- **REFACTOR:** close rationalization loopholes surfaced in testing; micro-test the description wording for old-vs-new discrimination (no-guidance control, 5+ reps, manual read of every flagged match).
- Use the `evals/` harness (superpowers-evals) where a full-session eval is warranted.

## Compatibility

- Old skill directory: **zero edits** (byte-identical guarantee).
- Zero edits to: executing-plans, requesting-code-review, using-git-worktrees, test-driven-development, finishing-a-development-branch, `deploy/agents/`.
- Accepted cost of the full copy: future fixes to the sequential skill must be mirrored manually into the parallel copy; upstream merges touch only the sequential copy.

## Error handling

- Merge conflict → rebase fix subagent + mandatory re-review (Component 1).
- BLOCKED / NEEDS_CONTEXT / DONE_WITH_CONCERNS: handled per task exactly as in the old skill, without stalling other pipelines.
- Failed task with dependents: dependents stay pending; independent DAG branches continue; if unresolvable, stop per the old skill's escalation rules.
- Context compaction: ledger + git reconstruct full scheduler state.

## Out of scope

- Parallelism inside a single task.
- Any change to the sequential skill or executing-plans.
- Runtime dependency inference.
