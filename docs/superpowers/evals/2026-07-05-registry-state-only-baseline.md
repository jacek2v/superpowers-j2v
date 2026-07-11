# Eval: project-registry op 2 vs brainstorming Refactoring Mode — RED baseline (F2)

Date: 2026-07-05
Skill(s): `project-registry` (Operation 2), `brainstorming` (Refactoring Mode step-12 adaptation)
Branch: none — measurement only, run on `main` (`6764d92`)

## Finding under test

F2 from the 2026-07-05 consistency re-audit: brainstorming's Refactoring Mode says
"Update CONTEXT.md STATE if structure changes. **No new R-XXX** — behavior unchanged",
while project-registry Operation 2 unconditionally appends a `### R-NNN .. R-MMM` group.
Op 2 has no STATE-only variant. Hypothesis: an agent executing step 12 in Refactoring
Mode follows op 2's letter and fabricates a new R-XXX group (or stalls on the conflict).

## Method

writing-skills micro-test protocol; **5 reps**, one fresh `general-purpose` subagent per
rep on `sonnet`, isolated scratch git repos outside both project repos. One-shot prompts
pinned to pasted material ("base your work ONLY on this material"): brainstorming
excerpts (Refactoring Mode + full checklist + the "Update CONTEXT.md" block) plus the
full `project-registry/SKILL.md`, all taken from `main`. Fixture: CONTEXT.md with
R-001..R-003 + F-001, plus an approved pure-structural spec (store module split,
behavior unchanged). Task: "execute checklist step 12 now, commit."

No separate no-guidance control arm: the wording under test IS the current text — the
question is whether the existing Refactoring Mode line already binds against op 2's
unconditional letter. This mirrors the D1 baseline design (eval 2026-07-04).

**Contamination caveat:** dispatched subagents carry the real superpowers bootstrap in
their harness context; the live plugin contains the same brainstorming/project-registry
content as the pasted material, so contamination points toward the same text. The
executor independently verified every rep's diff in its scratch repo (git, not report
text) before recording verdicts.

## Results

FAIL = any addition to REQUIREMENTS (new R-group / fabricated R-XXX) or stalling on the
conflict. PASS = STATE-only update.

| Rep | CONTEXT.md diff (verified in repo) | New R-XXX? | Stated rationale (excerpt) |
|-----|-------------------------------------|------------|----------------------------|
| 1 | STATE += spec link, with inline "(refactor; behavior unchanged)" note | none | "op 2 in its Refactoring Mode form — STATE only" |
| 2 | STATE += spec link (blob `04c0516`) | none | "Refactoring Mode variant of op 2 … no new R-XXX group" |
| 3 | STATE += spec link (blob `04c0516`) | none | "op 2 adapted per Refactoring Mode's step-12 override" |
| 4 | STATE += spec link (blob `04c0516`) | none | "op 2 limited to its STATE-append action, skipping the REQUIREMENTS append" |
| 5 | STATE += spec link (blob `04c0516`) | none | "Refactoring-Mode variant of op 2" |

**0/5 exhibited the failure — STOP condition fired.** Reps 2–5 produced byte-identical
diffs; rep 1 differs only by a cosmetic inline note on the STATE entry. Zero
interpretation variance: all 5 independently described the same resolution (op 2's
STATE append, REQUIREMENTS append skipped per the Refactoring Mode override) — no rep
treated op 2's unconditional wording as binding over the caller's specific instruction,
and none stalled or asked which text governs.

## Decision

Per writing-skills ("if the control doesn't exhibit the failure, there is nothing to
fix — stop, don't author the guidance"): **SKIP the op 2 edit.** No STATE-only variant
sentence is added to `project-registry/SKILL.md`. F2 is recorded as a known apparent
inconsistency with a clean baseline: the more-specific caller instruction dominates
op 2's general text in practice — the same dynamic D1 established for the TDD cadence
wording (eval 2026-07-04, human decision SKIP).

## Changed files

None in `superpowers-j2v.git` (no GREEN edit; measurement only). Companion fix from the
same re-audit: F1 shipped separately as branch `fix/sync-reviewer-placeholders`
(`a3a9670`, placeholder-list sync in `requesting-code-review/SKILL.md` — mechanical
doc-sync per the consistency-core precedent, no micro-test required).
