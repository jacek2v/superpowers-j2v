# Eval: brainstorming deep research (parallel read-only research subagents)

Date: 2026-07-28
Skill(s): `brainstorming` (checklist steps 5 and 9, research prose, Process
Flow digraph, new `## Deep Research` section) + new reference file
`skills/brainstorming/research-subagents.md` — spec
`specs/2026-07-28-brainstorming-subagent-research-design.md`, decisions
D-029..D-033.
Method: writing-skills RED → edit → GREEN. Scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos) against the new `feedmix` fixture;
R2–R4 are multi-turn via `--session-id`/`--resume` with scripted answers.
Budget (human-approved via the implementation plan): baselines R1×2 R2×1
R3×1; GREEN R1×2 R2×2 R3×2 R4×1 (+re-runs after fixes). Branch:
`feat/brainstorm-deep-research` off `main`.

Scenario ↔ assertion map: R1→proposal exists and is its own message;
R2→acceptance-gated dispatch, trimmed list honoured, per-decision approval,
persistence; R3→no behavior change in well-known territory; R4→decline path.
Contamination caveat: toy sessions inherit the real plugin bootstrap; the
loaded skill content is the same text under test, so contamination points
toward the same text (2026-07-05 precedent).

## RED baselines
(to fill in T2)

## GREEN results
(to fill in T5)

## Refactor loop
(to fill in T5; "none needed" if empty)
