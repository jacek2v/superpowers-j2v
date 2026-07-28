# Brainstorming: Subagent Deep Research — Design

Date: 2026-07-28
Status: approved

## Problem

The brainstorming skill's step 5 ("Research sanity check") is a quick inline check,
skipped in well-known territory. For questions that need real investigation —
architecture choice, library comparison, unfamiliar domain — the skill rushes to a
spec that leaves those decisions open. The spec should instead carry decisions
already made, grounded in research.

## Solution Overview

Extend step 5 into two tiers. The quick inline check stays as-is. A new deep tier
dispatches parallel read-only research subagents; their findings feed decisions the
human partner approves one by one, and those decisions are baked into the spec.
Mechanism details live in a reference file (`research-subagents.md`), loaded only
when deep research is accepted — the same pattern as `visual-companion.md`.

## Flow

1. **Trigger.** When open design decisions warrant deep research (unfamiliar
   domain, architecture choice, library comparison), the skill proposes it. The
   proposal is its own message: list of research questions, chosen mode, subagent
   count. Nothing runs until the human partner accepts; they may trim or edit the
   question list. On acceptance, the skill reads
   `skills/brainstorming/research-subagents.md` and follows it.
2. **Modes** — the skill picks one and names it in the proposal:
   - **Per-decision**: each open decision = one research question = one subagent.
     Runs before "Propose 2-3 approaches" and feeds it.
   - **Per-approach**: the skill first sketches 2-3 approaches as today, then one
     subagent deepens each (feasibility, prior art, risks). Runs after the sketch,
     before the recommendation.
3. **Dispatch.** All subagents launch in a single message (parallel). Each is
   read-only: codebase, web, library docs. Each returns structured findings:
   options, trade-offs, recommendation, sources. A subagent never makes a
   decision and never writes files.
4. **Decisions.** The main agent presents findings + recommendation per decision;
   the human partner approves each decision separately. Approved decisions ground
   the approaches/design and pass the normal op-4 gate before presentation
   (D-021 unchanged; D-009/D-017: only the main agent gates).
5. **Persistence.** The spec gets a decisions section with short rationales. Full
   findings (rejected options, comparisons, sources) go to
   `docs/superpowers/research/YYYY-MM-DD-<topic>-analysis.md`, committed together
   with the spec.

## File Changes

- `skills/brainstorming/SKILL.md` — extend step 5 (two tiers), update the dot
  flow diagram, add a short "Deep Research" section pointing at the reference
  file (mirroring the Visual Companion section's shape).
- `skills/brainstorming/research-subagents.md` (new) — proposal criteria,
  proposal template, subagent prompt template, structured findings format,
  analysis-file template.

## Constraints

- Registry compatibility: research findings are inputs, not decisions — every
  direction still passes the op-4 gate via the main agent (D-021, D-009, D-017).
- No behavior change when deep research is never proposed or is declined: the
  quick inline sanity check works exactly as before.
- Subagents are read-only and stateless; all synthesis and presentation happens
  in the main agent.

## Testing

Per fork CLAUDE.md, skill changes require evaluation: add a pressure-test
scenario under `evals/` exercising the propose → accept → dispatch → per-decision
approval path, with before/after results.
