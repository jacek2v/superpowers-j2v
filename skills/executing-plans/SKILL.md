---
name: executing-plans
description: Use when you have a written implementation plan to execute and subagent dispatch is unavailable
---

# Executing Plans

## Overview

Load plan, review critically, execute all tasks, report when complete.

**Announce at start:** "I'm using the executing-plans skill to implement this plan."

**Note:** Tell your human partner that Superpowers works much better with access to subagents. The quality of its work will be significantly higher if run on a platform with subagent support (Claude Code, Codex CLI, Codex App, and Copilot CLI all qualify; see the per-platform tool refs in `../using-superpowers/references/`). If subagents are available, use superpowers:subagent-driven-development instead of this skill.

## The Process

### Step 1: Load and Review Plan
1. Ensure an isolated workspace exists — **REQUIRED SUB-SKILL:** superpowers:using-git-worktrees
2. Read plan file
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed

### Step 2: Execute Tasks

For each task:
1. Mark as in_progress in TodoWrite
2. Follow each step exactly (plan has bite-sized steps)
3. Run verifications as specified
4. Mark as completed in TodoWrite

### Gate Steps (Gated Testing Mode)

Plans for projects declaring `## Gated testing` contain **Gate RED / Gate GREEN** steps (activation, round format, valid-RED criteria: superpowers:test-driven-development — Gated Testing Mode). No declaration → no gate steps exist; skip this section. At a gate step:

1. STOP. No code edits of any kind while a gate is open.
2. Fill the plan's round request: next round number from the round ledger (`.superpowers/rounds.md`), actual file list, the single-line command, expected outcome. Append the "issued" ledger line.
3. Default runner (operator): post the round request and WAIT for your human partner's pasted output — never proceed on silence, assumptions, or partial output. `Runner: claude`: execute the command on the test system yourself.
4. Judge the output and append the verdict ledger line: Gate RED — every new test against the valid-RED criteria; Gate GREEN — full suite green.
5. Invalid RED → fix the TESTS → re-round narrowed to the affected files. GREEN failures → fix the CODE, never the test → narrowed or full GREEN re-round.
6. Past a gate only with valid round evidence for the current code state — any later edit invalidates it.

### Step 3: Register Feature

After all tasks complete and verified, update the project registry using the project-registry skill (operation 4):
- Remove spec entry from STATE
- Add F-XXX entry to FEATURES with date and list of satisfied R-XXX
- Commit CONTEXT.md changes

### Step 4: Complete Development

After CONTEXT.md is updated:
- Announce: "I'm using the finishing-a-development-branch skill to complete this work."
- **REQUIRED SUB-SKILL:** Use superpowers:finishing-a-development-branch
- Follow that skill to verify tests, present options, execute choice

## When to Stop and Ask for Help

**STOP executing immediately when:**
- Hit a blocker (missing dependency, test fails, instruction unclear)
- Plan has critical gaps preventing starting
- You don't understand an instruction
- Verification fails repeatedly

**Ask for clarification rather than guessing.**

## When to Revisit Earlier Steps

**Return to Review (Step 1) when:**
- Partner updates the plan based on your feedback
- Fundamental approach needs rethinking

**Don't force through blockers** - stop and ask.

## Remember
- Review plan critically first
- Follow plan steps exactly
- Don't skip verifications
- Reference skills when plan says to
- Stop when blocked, don't guess
- Never start implementation on main/master branch without explicit user consent

## Integration

**Required workflow skills:**
- **superpowers:using-git-worktrees** - Ensures isolated workspace (creates one or verifies existing)
- **superpowers:writing-plans** - Creates the plan this skill executes
- **superpowers:project-registry** - Register completed feature in CONTEXT.md (operation 4) after all tasks, before finishing
- **superpowers:finishing-a-development-branch** - Complete development after all tasks
