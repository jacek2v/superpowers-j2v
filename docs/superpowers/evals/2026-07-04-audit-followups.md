# Eval: audit follow-ups — validate shipped conditionals (T1–T4) + D1/D2/D4a/D4b edits

Date: 2026-07-04
Skill(s): `subagent-driven-development` (implementer-prompt, task-reviewer-prompt),
`finishing-a-development-branch`, `test-driven-development`, `requesting-code-review`,
`project-registry`, `brainstorming`
Method: writing-skills protocol; **5 reps per arm per condition** (spec bar "5+ reps
per arm"). One fresh `general-purpose` subagent per rep on `sonnet`, isolated `/tmp`
repos / one-shot prompts, fresh context per sample. The executor read every rep's raw
output/report before recording a verdict (template echoes do not count as hits).
Branch: `fix/audit-followups` off `main` (`3f341e3`) in `superpowers-j2v.git`.

T1–T4 are measurement-only: they re-validate the already-shipped conditionals
`ad42469` (TDD default + waiver, task-reviewer TDD gate) and `d5057a1` (finishing
Step 4 review-status gate) at the spec's 5-rep bar. D1/D2/D4a/D4b are the new edits.

## Contamination caveat (applies to every test below)

Dispatched subagents carry the real superpowers bootstrap and skill list in their own
harness context. Every one-shot prompt therefore pinned them to the pasted material
("base your answer ONLY on this material"). This limitation is real and is called out
per-test where it matters (notably T2 and D4b).

---

## T1 — waiver-line recognition (shipped implementer-prompt, 5 reps)

Doc-only brief carrying `TDD: waived — documentation only, no production code.`
Pass = (a) no fabricated test files AND (b) report's TDD Evidence quotes the waiver.

| Rep | Commit  | Test files? | Waiver quoted verbatim (em-dash) | Verdict |
|-----|---------|-------------|----------------------------------|---------|
| 1   | d9449b4 | none (README only) | yes | PASS |
| 2   | bf08db2 | none | yes | PASS |
| 3   | 5fdacbd | none | yes | PASS |
| 4   | 4810e0a | none | yes | PASS |
| 5   | 2b2d73e | none | yes | PASS |

**5/5 PASS.** No failing rep — nothing to quote. The shipped `ad42469` waiver wording
holds at the 5-rep bar (prior eval was 3/3 at the 3-rep budget).

## T2 — silent brief, the closed loophole (3 arms × 5 reps)

Silent brief asks for tests but never mentions TDD/test-first/waivers. Arm `new` =
shipped implementer-prompt; arm `old` = `ad42469~1` ("following TDD if task says to");
arm `ctl` = no-guidance control. test-first = RED-before-GREEN evidence quoted (a bare
TDD claim without RED counts as skips).

| Arm | test-first /5 | Evidence |
|-----|---------------|----------|
| new | 5/5 | every rep quoted RED `ModuleNotFoundError: No module named 'slugify'` before slugify.py existed, then GREEN |
| old | 5/5 | same RED-before-GREEN evidence in all 5 |
| ctl | 5/5 | same — even with NO TDD guidance in the prompt |

**Step-5 gate (new arm): 5/5 test-first — PASS, no STOP.** No failing rep to quote.

**Step-6 interpretation verdict — Saturated environment.** old 5/5 and ctl 5/5 both
went test-first. The no-guidance control still did TDD in 5/5, confirming the
contamination caveat: the subagent harness loads the real superpowers bootstrap, which
mandates TDD independent of the pasted implementer prompt. T2 cannot discriminate the
`new` vs `old` wording in this harness. NOT a ship-blocker (`ad42469` already shipped;
new arm 5/5, zero regression). Matches the 2026-07-04 prior eval (old arm 3/3
test-first). **Flagged to human.** No materially divergent reading of the brief across
reps (tooling varied — uv vs python3, ASCII vs Unicode alnum — but not the test-first
behavior under judgment); no interpretation-variance fail signal.

## T3 — task-reviewer TDD-evidence gate (2 arms × 5 reps)

Arm A: code task, report has NO TDD Evidence and no waiver → reviewer must flag it
Critical/Important. Arm B: doc task, report quotes the waiver → reviewer must NOT raise
a Critical/Important TDD finding.

| Arm | rep 1 | 2 | 3 | 4 | 5 | Verdict |
|-----|-------|---|---|---|---|---------|
| A (must flag) | Important | Important | Important | Important | Important | 5/5 PASS |
| B (must accept waiver) | Approved | Approved | Approved | Approved | Approved | 5/5 PASS |

**5/5 PASS each arm.** No failing rep. Every Arm-A reviewer confirmed the code was
correct yet still flagged missing TDD Evidence as Important; every Arm-B reviewer
independently verified the doc example against `slugify.py` and accepted the quoted
waiver — accurate praise, not template echo. The `ad42469` reviewer wording
(task-reviewer-prompt lines 66–70) discriminates cleanly.

## T4 — finishing Step 4 review gate (2 arms × 5 reps)

Scenario: branch `feat/widget`, tests pass, base `main`, no review this session.
"surfaces review" = states no review happened / status unknown and offers a review
before (or instead of) the 4-option menu.

| Arm | surfaces review /5 | Evidence |
|-----|--------------------|----------|
| new (`d5057a1`) | 5/5 | e.g. "This branch hasn't been reviewed yet — no reviewer ran this session. Want me to dispatch a code review now…" |
| old (`d5057a1~1`) | 0/5 (5/5 straight to menu) | verbatim 4-option menu, zero review mention |

**new 5/5, old 0/5 — clean delta, PASS, no STOP.** The shipped review-status check
closes the gap the old text left open. No failing new-arm rep to quote.

---

## D1 — cadence scoping sentence in Verify GREEN (RED baseline → STOP)

Hypothesis: the TDD skill's "Other tests still pass" bullet reads as
full-suite-per-GREEN and overrides the SDD dispatch prompt's focused-cadence
instruction. RED baseline (5 reps) fed the full current `test-driven-development/SKILL.md`
(sha1 `ddb28bf`, 371 lines, verified identical to the on-branch file) plus the dispatch
cadence instruction; scenario = TDD cycle 2 of ~4, focused test just passed.
full-suite-per-GREEN = runs the whole suite now; focused-cadence = defers full suite to
pre-commit.

| Rep | Choice | Justification (verbatim excerpt) |
|-----|--------|----------------------------------|
| 1 | focused-cadence | "the skill's Verify GREEN step is satisfied by the focused test — it doesn't mandate a full-suite run at every cycle boundary… defer the one full-suite run to immediately before the final commit" |
| 2 | focused-cadence | "a full run now would violate that instruction without adding new information" |
| 3 | focused-cadence | "the full suite runs only once, right before the final commit after cycle 4, not after every cycle's GREEN" |
| 4 | focused-cadence | "reserve full-suite runs for once before the final commit… satisfying what's due at this point" |
| 5 | focused-cadence | "the dispatch instructions explicitly say the full suite runs once before the final commit, not after every cycle" |

**0/5 full-suite-per-GREEN — STOP CONDITION FIRED.** The baseline does not exhibit the
premised conflict: the dispatch prompt's explicit cadence instruction already dominates
the skill's "Other tests still pass" bullet, and several reps explicitly noted the skill
does not mandate a full-suite run per cycle. Per writing-skills there is nothing to fix
(RED did not fail). **Human decision (2026-07-04): SKIP D1** — do not apply the scoping
sentence. The branch therefore carries 3 commits, not 4; this is a legitimate
plan-sanctioned reduction ("fewer only if a STOP condition legitimately fired").

## D2 — pointer to receiving-code-review (mechanical, grep-verified)

`skills/requesting-code-review/SKILL.md` "3. Act on feedback" now carries a
`REQUIRED SUB-SKILL: Use superpowers:receiving-code-review before implementing fixes`
line. Spec D2 mandates no micro-test; verified by grep (one match, correct block).
Commit `6d60dc7`.

## D4a — project-registry description (unconditional, grep-verified)

Rewrote the `project-registry` frontmatter `description` to "Use when…" form and dropped
the operation-by-caller summary (the SDO trap). Keywords retained (`CONTEXT.md`, `R-XXX`,
`F-XXX`, "Not user-invocable directly"); frontmatter still parses. Commit `6302c65`.

## D4b — brainstorming description, discriminator A/B (2 arms × 6 tasks × 5 reps = 60)

Old arm = imperative "You MUST use this before any creative work…". Candidate arm =
"Use when starting any creative work — … — before writing any code…". Skill lists
generated from the branch (with D4a's new project-registry desc); the arms differ by
exactly the brainstorming line (15 skills per list).

| Task | old brainstorming /5 | cand brainstorming /5 |
|------|----------------------|-----------------------|
| T-A "Let's make a react todo list" (acceptance test) | 4 | 4 |
| T-B "add dark mode to the app" | 5 | 4 |
| T-C "build a CLI tool for X" | 5 | 4 |
| N-A "fix this bug" (false-positive count) | 0 | 0 |
| N-B "explain this code" (FP) | 0 | 0 |
| N-C "why is this test flaky" (FP) | 0 | 0 |

Trigger totals: old 14/15, cand 12/15. Non-trigger FP totals: old 0, cand 0.

**Gate** ships iff ALL: (1) cand T-A = 5/5; (2) cand ≥ old on each trigger; (3) cand FP
total ≤ old FP total.
- (1) cand T-A = 4/5 → **FAIL**
- (2) T-B cand 4 < old 5, T-C cand 4 < old 5 → **FAIL**
- (3) 0 ≤ 0 → pass

**GATE FAILS (criteria 1 & 2) → fail branch fired.** Kept the imperative "You MUST use
this…" description untouched; added a deliberate-tested-exception comment above
`# Brainstorming Ideas Into Designs`. Commit `6764d92`.

Every non-brainstorming trigger pick was `superpowers:using-superpowers` (the bootstrap
meta-skill named as invoked-first) — never a wrong domain skill. Verbatim: the candidate
arm's defectors returned exactly `superpowers:using-superpowers` on T-A rep2, T-B rep1,
T-C rep1. This is a sim artifact of pasting the bootstrap as data, but it is symmetric
enough across arms that the delta still discriminates: the imperative wording triggered
brainstorming 14/15, the "Use when…" rewrite only 12/15 — a real, if small,
auto-triggering regression. Neither arm false-fired brainstorming on any non-trigger
task (both correctly chose systematic-debugging / using-superpowers / NONE).

---

## Changed files (branch `fix/audit-followups`, 3 commits)

- `6d60dc7` D2 — `skills/requesting-code-review/SKILL.md` (receiving-code-review pointer).
- `6302c65` D4a — `skills/project-registry/SKILL.md` (Use-when description).
- `6764d92` D4b — `skills/brainstorming/SKILL.md` (tested-exception comment; description kept).

D1 not applied (STOP fired, human chose SKIP). No SDD files, no
`finishing-a-development-branch`, no `evals/` harness touched (spec D5 non-changes).

## Note on deployment

`docs/marketplace/superpowers` is a symlink to `superpowers-j2v.git` — branch edits are
live in the active plugin immediately. Integration (merge) is deliberately left to
`superpowers:finishing-a-development-branch` after human review.
