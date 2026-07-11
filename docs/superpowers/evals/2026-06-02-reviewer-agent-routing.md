# Eval: reviewer dispatch must not hijack a registered code-review agent

Date: 2026-06-02
Skill(s): `subagent-driven-development`, `requesting-code-review`
Method: writing-skills RED-GREEN-REFACTOR, 4 subagents per phase.

## Problem (real session)

While running `superpowers:subagent-driven-development`, the orchestrator
dispatched the third-party agent `feature-dev:code-reviewer` for review steps.
The skills never reference that agent. The intended mechanism (stated in
`requesting-code-review/SKILL.md` and `code-quality-reviewer-prompt.md`) is a
`general-purpose` subagent filled with the `requesting-code-review/code-reviewer.md`
template.

## Root cause

Name collision. The skill prose says "dispatch **code reviewer** subagent" and
the example said `[Dispatch final code-reviewer]` (hyphenated, matching the
registered agent name). When a `subagent_type` literally named `…code-reviewer`
exists, the orchestrator picks it as "purpose-built" — keeping the template but
swapping the agent type. A specialized review agent carries its own persona and
methodology that override the template, so the intended review behavior is lost.
The final-review step was most exposed: it had no template pointer at all.

## RED (baseline, current text) — 4 agents

Scenario: orchestrator at the per-task code-quality review and the final review,
with `feature-dev:code-reviewer` among the available `subagent_type` values.

| Agent | per-task | final |
|---|---|---|
| 1 | general-purpose ✅ | general-purpose ✅ |
| 2 | feature-dev:code-reviewer ❌ | feature-dev:code-reviewer ❌ |
| 3 | feature-dev:code-reviewer ❌ | feature-dev:code-reviewer ❌ |
| 4 | feature-dev:code-reviewer ❌ | feature-dev:code-reviewer ❌ |

**3/4 misrouted**, even at the per-task step that already says
`Task tool (general-purpose)`. Verbatim rationalizations:
- "my environment provides a dedicated code-reviewer subagent, which is the better match"
- "the purpose-built feature-dev:code-reviewer subagent that matches that intent exactly"
- "Dedicated code-reviewer subagent matches the skill's code-quality review step better than a generic agent"

Pattern: "dedicated/purpose-built reviewer beats general-purpose."

## GREEN (after fix) — same 4 scenarios

| Agent | per-task | final |
|---|---|---|
| 1–4 | general-purpose ✅ | general-purpose ✅ |

**0/4 misrouted.** All cite the new counter ("feature-dev:code-reviewer would
override the template with its own methodology"). REFACTOR surfaced no new
rationalizations.

## Change (3 files, source repo only)

- `requesting-code-review/SKILL.md` — explicit "always general-purpose, never a
  specialized review agent" counter at the dispatch step + Red Flag entry.
- `subagent-driven-development/code-quality-reviewer-prompt.md` — same counter at
  the per-task review.
- `subagent-driven-development/SKILL.md` — final-review step given the missing
  template pointer; example de-baited (`code-reviewer` → explicit dispatch line);
  Red Flag entry.

Core counter (closes the observed rationalization): keeping the template but
swapping the agent type is still wrong, because the specialized agent overrides
the template.

## Note on deployment

`docs/marketplace/superpowers` is a **symlink** to `superpowers-j2v.git` — the
same repo. Editing the source updates the active plugin's files directly; only
`/reload-plugins` is needed for the runtime to pick the change up.
