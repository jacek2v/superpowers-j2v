# Eval: Gated round request `Paste back:` slot (+ dropped plan-bookkeeping rule)

Date: 2026-07-24
Skill(s): `test-driven-development` (Gated Testing Mode — Round Request);
`subagent-driven-development`, `subagent-driven-development-parallel`
(investigated, left unchanged)
Method: writing-skills RED → edit → GREEN. Wording micro-tests = fresh
general-purpose subagents (sonnet, one-shot, isolated context), 5 reps per
arm; scenario A additionally verified against real sandbox git repos
(`git status --porcelain`), not self-reports alone. Production baseline =
transcript analysis of a real SDD session in the <gated project> project
(session `8ae1232e`, 2026-07-23/24, coordinator context peaked at 511,787
tokens).
Commit under test: `f062e2c` on `main`.

## Motivation (production evidence)

Context breakdown of session `8ae1232e` showed the single largest consumer
was operator-pasted gated-round output: ~334 KB across 7 pastes (two of
104 KB each), ~100–150k tokens. All 10+ round requests in the session
followed the Round Request template faithfully (ROUND/Source/Files/
Command/Expected all present) but none constrained what the operator
pastes back. The existing bullet "Use output-friendly flags (e.g. `pytest
-q --tb=short`) — pastes must stay small" did not transfer to a runner
(`Run-Tests.ps1`, Pester 5) with no advertised quiet flag.

Failure classification per writing-skills "Match the Form to the Failure":
omitted element in an output the agent already produces → structural fix
(required template slot), not another prose bullet.

## Scenarios

- **A — SDD bookkeeping** (hypothesis: coordinator re-opens/edits the plan
  file for status ticking): mid-execution `subagent-driven-development`
  state, clean Task 2 review verdict, plan file with writing-plans-style
  `- [ ]` step checkboxes, ledger present, subagent dispatch disabled.
  Sandboxed git repo per rep. Failure signal: any plan-file modification.
- **B — Gate RED round request** (hypothesis: request does not constrain
  the paste): Gated Testing Mode active, verbose Pester runner with no
  quiet flag, ~1000-test suite, 21 new failing tests. Failure signal: no
  instruction on what the operator returns.

## RED baselines (unmodified skills)

| Scenario | Reps | Failure rate | Notes |
|---|---|---|---|
| A | 5 | 0/5 | All reps edited ONLY `.superpowers/sdd/progress.md` (verified via `git status` in each sandbox); plan read once for task names, never modified |
| B | 5 | 5/5 | All reps emitted a faithful ROUND block with zero paste constraint; 2/5 narrowed `Command:` with `-Path` unprompted, still no paste contract |

Production corroboration: scenario B matches the real session exactly
(bare full-suite commands, 104 KB pastes). Scenario A's hypothesis is also
refuted by production — the session's 10 plan-file edits were substantive
plan amendments (task redefinition, command corrections), not bookkeeping.

**Scenario A verdict: control does not exhibit the failure → no guidance
authored.** Per the Iron Law, the planned "plan is read once / status
lives only in the ledger" rule for both SDD skills was dropped. Both SDD
skills already carry the relevant machinery (File Handoffs +
`scripts/task-brief`, Durable Progress ledger, "Make a subagent read the
whole plan file" red flag), and the session complied with it (30/34
dispatches referenced brief files, prompts 3–4 KB).

## GREEN (edited `test-driven-development`)

Edit: Round Request template gains one fixed line —
`Paste back: the run's summary counts + every failure/error with its
message; passing tests stay out of the paste` — plus one sentence stating
the line is verbatim part of every round request. The contract preserves
all verdict-relevant signal: RED failures and INVALID errors are pasted in
full; only passing-test noise is excluded.

| Scenario | Reps | Compliance | Variance |
|---|---|---|---|
| B | 5 | 5/5 | `Paste back:` line identical in all 5; rest of block faithful; 5/5 also narrowed `Command:` with `-Path` |

Baseline/green distributions fully separated (0/5 → 5/5). No rep
negotiated or paraphrased the slot content; no new rationalizations
observed → no REFACTOR counters needed.

## Coverage gaps (accepted)

- Micro-tests only; no full `claude -p` toy-session run. The slot is a
  template-shape change in an already template-compliant flow (production
  showed 10/10 template fidelity), so one-shot fidelity is the operative
  question.
- Coordinator role tested on sonnet; real sessions often run opus. A
  weaker model complying is treated as the harder case.
- Operator-side deploy pastes (e.g. 104 KB `Deploy-SQLs.ps1` output at a
  Gate GREEN pre-step) are outside any round template — fix belongs in the
  project's runner scripts (summary mode), not in a skill.

## Deployment

`f062e2c feat(tdd): add required Paste back: slot to gated round request
template` on `main` in `superpowers-j2v.git`. Both SDD variants inherit
the template via their Gated Testing Mode sections; no SDD file changed.
