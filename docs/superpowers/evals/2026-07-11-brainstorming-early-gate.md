# Eval: brainstorming early gate (gate every direction before presenting)

Date: 2026-07-11
Skill(s): `brainstorming` (checklist steps 2/7/8, Process Flow digraph, two
prose bullets) — spec `specs/2026-07-11-brainstorming-early-gate-design.md`,
decision D-021.
Method: writing-skills RED → edit → GREEN. Scenarios = `claude -p` toy
sessions (sonnet, isolated /tmp repos); V2–V4 are multi-turn via
`--session-id`/`--resume` with scripted answers; fixtures reused read-only
from `decision-log/`. Budget (human-approved via the implementation plan):
baselines V1×1 V2×2 V3×2 V4×1; GREEN V1×1 V2×2 V3×2 V4×2 (+re-runs after
fixes). Branch: `feat/brainstorm-early-gate` off `main`.

Scenario ↔ spec-variant map: V1→variant 1 (request collision, gate before the
first clarifying question), V2→variant 2 (approach never a plain option),
V3→variant 3 (amendment caught pre-spec), V4→variant 4 (no gate noise).
Not exercised (accepted): the no-registry control — D-020 already evidenced
by the decision-log suite's S6, and every changed behavior stays keyed on the
step-2 CONTEXT.md-exists condition. Contamination caveat: toy sessions
inherit the real plugin bootstrap; the loaded skill content is the same text
under test, so contamination points toward the same text (2026-07-05
precedent).

## RED baselines
(to fill in T2)

## GREEN results
(to fill in T4)

## Refactor loop
(to fill in T4; "none needed" if empty)
