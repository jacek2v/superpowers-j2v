# Eval: reviewer dispatch target and model in `requesting-code-review`

Date: 2026-08-05
Skill(s): `requesting-code-review` (SKILL.md + code-reviewer.md);
`subagent-driven-development` (read as context, left unchanged)
Method: writing-skills RED → edit → GREEN → REFACTOR → GREEN. Wording
micro-tests = fresh one-shot sessions (`claude -p ... --model sonnet
--output-format json --add-dir "$ROOT"`), 5 reps per arm per probe, fixtures
under `/tmp` holding only the skill files each arm should see. RED fixture =
`git show HEAD:skills/requesting-code-review/*` (pre-edit text), GREEN =
working tree. Both arms run the same day.
Commit under test: `10b0cda` on `main`.
Budget: 25 reps, $3.22 total.

## Motivation

`requesting-code-review` told the agent to dispatch `general-purpose` with
"the most capable available model", while
`subagent-driven-development/SKILL.md:117,308` routes every reviewer —
including the final whole-branch review, which uses this very template —
through the `sdd-reviewer` agent (sonnet/xhigh). The two skills disagreed on
both the dispatch target and the model. The `sdd-reviewer` routing is the
measured one (see `MODEL_EFFORT.md`, migration 2026-07-19); the
`requesting-code-review` wording predates it (`c40f957`, `9d06d21`).

Failure classification per writing-skills "Match the Form to the Failure":
the agent fills a slot in a template it already produces, and fills it wrong
→ structural fix in the slot and its dispatch line, not a prose warning.

## Probes

- **P1 (standalone):** finished branch outside any SDD workflow; only
  `requesting-code-review/{SKILL.md,code-reviewer.md}` in the fixture. Asked
  for (a) subagent/agent type, (b) model value.
- **P2 (SDD final review):** orchestrator after the last task; fixture adds
  `subagent-driven-development/SKILL.md`. Asked for (a), (b) and (c) whether
  the two skills disagree.

Every result read manually from `.result`; no automated scoring.

## RED (pre-edit text)

| Probe | Result |
|---|---|
| P1 | 5/5 `general-purpose` + opus ("most capable available model", named `claude-opus-5` or `opus` explicitly) |
| P2 | 5/5 picked `sdd-reviewer` + sonnet, but 5/5 also reported the conflict and had to adjudicate it, all citing `SKILL.md:38` / `code-reviewer.md` against SDD |

So the conflict was real and visible to the agent: inside SDD it was resolved
correctly but only after adjudication, and outside SDD the same template sent
the review to opus.

## GREEN (first edit)

Dispatch line changed to `sdd-reviewer` with a `general-purpose` + `model:
sonnet` fallback; `[MODEL]` slot redefined to `sonnet`; example and Red Flags
bullet updated; the anti-specialized-agent rule kept, with `sdd-reviewer`
described as a bare passthrough carrying only model and effort.

| Probe | Result |
|---|---|
| P1 | model 5/5 `sonnet`; agent 3/5 `sdd-reviewer`, 2/5 `general-purpose` — both fallbacks justified by reading the agent's *name* as an SDD-only scope ("nie w SDD, więc `sdd-reviewer` nie jest zainstalowany") |
| P2 | 5/5 `sdd-reviewer` + sonnet, 5/5 "no conflict" |

Model was fixed everywhere, but the agent choice was noisy — the fallback
clause was being read as a workflow condition instead of a registry
condition.

## REFACTOR

Dispatch line now states that the agent's name records where it came from,
not where it may be used, and gates the fallback on the agent being missing
from the registry; the template header says "in SDD and standalone alike".

| Probe | Result |
|---|---|
| P1 (re-run) | 5/5 `sdd-reviewer`, 5/5 named sonnet as the model and left the `[MODEL]` slot unfilled because the agent carries it |

Variance gone; P2 not re-run — its wording was already 5/5 in GREEN and the
refactor only touched the clause P2 never exercised.

## Caveats

- Probes measure the stated dispatch, not an executed one: no reviewer
  subagent was actually spawned.
- All reps ran on sonnet; the orchestrator role runs on opus in real sessions.
- `general-purpose` fallback path is now untested by construction — no arm
  had a fixture without the `sdd-reviewer` agent registered.
