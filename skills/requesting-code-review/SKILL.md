---
name: requesting-code-review
description: Use when completing tasks, implementing major features, or before merging to verify work meets requirements
---

# Requesting Code Review

Dispatch a code reviewer subagent to catch issues before they cascade. The reviewer gets precisely crafted context for evaluation — never your session's history. This keeps the reviewer focused on the work product, not your thought process, and preserves your own context for continued work.

**Core principle:** Review early, review often.

## When to Request Review

**Mandatory:**
- Final whole-branch review in subagent-driven development (per-task reviews use that skill's task-reviewer-prompt.md, not this template)
- After completing major feature
- Before merge to main

**Optional but valuable:**
- When stuck (fresh perspective)
- Before refactoring (baseline check)
- After fixing complex bug

## How to Request

**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base main HEAD)  # or the SHA you recorded before the work began
HEAD_SHA=$(git rev-parse HEAD)
```

Never use `HEAD~1` as the base of a multi-commit range — it silently drops every commit except the last.

**2. Dispatch code reviewer subagent:**

Dispatch a `general-purpose` subagent, filling the template at [code-reviewer.md](code-reviewer.md)

**Always `general-purpose` — never a specialized review agent.** Even if your environment offers a purpose-built reviewer (e.g. `feature-dev:code-reviewer`, or anything named `code-reviewer`), do not dispatch it. Those agents carry their own review persona and methodology that override this template. Keeping the template but swapping the agent type is still wrong — dispatch `general-purpose` so the reviewer follows only `code-reviewer.md`.

**Placeholders:**
- `{DESCRIPTION}` - Brief summary of what you built
- `{PLAN_OR_REQUIREMENTS}` - What it should do
- `{BASE_SHA}` - Starting commit
- `{HEAD_SHA}` - Ending commit

**3. Act on feedback:**

**REQUIRED SUB-SKILL:** Use superpowers:receiving-code-review before implementing fixes

- Fix Critical issues immediately
- Fix Important issues before proceeding
- Note Minor issues for later
- Push back if reviewer is wrong (with reasoning)

## Example

```
[All plan tasks complete; time for the final whole-branch review]

You: Let me request the final code review before finishing.

BASE_SHA=$(git merge-base main HEAD)
HEAD_SHA=$(git rev-parse HEAD)

[Dispatch code reviewer subagent]
  DESCRIPTION: Added verifyIndex() and repairIndex() with 4 issue types
  PLAN_OR_REQUIREMENTS: Task 2 from docs/superpowers/plans/deployment-plan.md
  BASE_SHA: a7981ec
  HEAD_SHA: 3df7661

[Subagent returns]:
  Strengths: Clean architecture, real tests
  Issues:
    Important: Missing progress indicators
    Minor: Magic number (100) for reporting interval
  Assessment: Ready to merge with fixes

You: [Fix progress indicators]
[Proceed to superpowers:finishing-a-development-branch]
```

## Integration with Workflows

**Subagent-Driven Development:**
- This template runs ONCE, as the final whole-branch review
- Per-task reviews use that skill's task-reviewer-prompt.md
- Fix Critical/Important findings before merge

**Executing Plans:**
- That skill runs where subagents are unavailable, so this template does not apply
- Ask your human partner to review the branch before merging

**Ad-Hoc Development:**
- Review before merge
- Review when stuck

## Red Flags

**Never:**
- Skip review because "it's simple"
- Ignore Critical issues
- Proceed with unfixed Important issues
- Argue with valid technical feedback
- Swap `general-purpose` for a specialized/registered code-review agent (e.g. `feature-dev:code-reviewer`) because it looks purpose-built

**If reviewer wrong:**
- Push back with technical reasoning
- Show code/tests that prove it works
- Request clarification

See template at: [code-reviewer.md](code-reviewer.md)
