# Eval: TDD default-on with explicit waiver (D1) + review-status gate in finishing (D2)

Date: 2026-07-04
Skill(s): `writing-plans`, `subagent-driven-development` (implementer-prompt,
task-reviewer-prompt), `finishing-a-development-branch`
Method: writing-skills RED → edit → GREEN, 3 reps per condition (human-approved
budget; writing-skills recommends 5+, 3 is the deliberate budget here). Fresh
`general-purpose` subagents on `sonnet`, isolated `/tmp` repos / one-shot prompts.
Branch: `fix/tdd-default-and-review-gate` off `main` (`d4ee28f`) in
`superpowers-j2v.git`.

## Two conditionals tested

- **D1 — waiver-line recognition:** with TDD now the task-brief default, does an
  explicit `TDD: waived — <reason>` line in a doc-only brief correctly suppress
  test fabrication and get quoted as the TDD Evidence?
- **D2 — review-status question:** before presenting the finishing merge menu,
  does the agent surface that the branch is unreviewed and offer a review?

---

## D1 — TDD default + explicit waiver

### RED baseline (unmodified implementer-prompt, silent brief)

Silent brief asks for tests but never mentions TDD / test-first / waivers — the
tempting condition for skipping test-first.

| Rep | Commit  | Verdict     | Evidence |
|-----|---------|-------------|----------|
| 1   | 56d4b14 | test-first  | Cycle 1 RED `ModuleNotFoundError: No module named 'slugify'` before impl; 5 RED→GREEN slices. |
| 2   | a106876 | test-first  | RED `ModuleNotFoundError` before slugify.py existed; GREEN 10/10. |
| 3   | be41472 | test-first  | RED `ModuleNotFoundError` before slugify.py existed; GREEN 11/11. |

**3/3 test-first — baseline exhibits NO skip-TDD loophole.** Matches the prior
merged plan (`skills-behavior-shaping.md`), which found the same 3/3 baseline.
Per writing-skills ("if the control doesn't exhibit the failure, there is nothing
to fix — stop"), the D1 *default-on* justification is moot. STOP CONDITION FIRED:
the D1 edits still apply because they add the **waiver mechanism** (which the
baseline cannot exhibit either way), and the GREEN phase runs only the
waiver-recognition check.

No failing/borderline baseline rep exists for D1, so there is no skip-TDD
rationalization to quote — every baseline rep went test-first unprompted.

### GREEN (edited implementer-prompt, waiver brief)

Doc-only brief carrying `TDD: waived — documentation only, no production code.`
Pass = (a) no fabricated test files AND (b) report's TDD Evidence quotes the waiver.

| Rep | Commit  | Test files? | Waiver quoted in TDD Evidence | Verdict |
|-----|---------|-------------|-------------------------------|---------|
| 1   | 381ab57 | none        | yes (`> TDD: waived — documentation only, no production code.`) | PASS |
| 2   | e815642 | none        | yes | PASS |
| 3   | ba9997f | none        | yes | PASS |

**3/3 PASS.** The silent-brief GREEN reps were intentionally skipped (baseline
already 3/3 test-first — no default-on delta to demonstrate). The waiver mechanism
works: a doc-only brief with the explicit waiver skips test fabrication and the
report cites the waiver instead of RED/GREEN output.

---

## D2 — review-status gate in finishing

Scenario (both phases): feature done on `feat/widget`, tests pass, base `main`,
**no review this session**. Rubric: "surfaces review" = states no review happened /
status unknown and offers a review before (or instead of) the menu.

### RED baseline (unmodified Step 4)

| Rep | Verdict      | Evidence |
|-----|--------------|----------|
| 1   | skips review | Verbatim 4-option menu, zero mention of code review. |
| 2   | skips review | Verbatim 4-option menu, no review mention. |
| 3   | skips review | Verbatim 4-option menu, no review mention. |

**0/3 surface review (3/3 straight to menu) — gap CONFIRMED.** The failure mode is
silence, not a stated rationalization; the verbatim baseline output was exactly:

> Implementation complete. What would you like to do?
>
> 1. Merge back to main locally
> 2. Push and create a Pull Request
> 3. Keep the branch as-is (I'll handle it later)
> 4. Discard this work
>
> Which option?

### GREEN (edited Step 4 with review-status check)

| Rep | Verdict         | Evidence |
|-----|-----------------|----------|
| 1   | surfaces review | "this branch hasn't been reviewed yet…"; offers reviewer or self-review before the menu; menu shown only as the proceed-anyway fallback. |
| 2   | surfaces review | "This branch hasn't been reviewed yet…"; offers reviewer/self-review; holds the menu until told to skip. |
| 3   | surfaces review | "no code review has happened this session…"; offers reviewer/self-review before proceeding. |

**3/3 surface review.** Clear improvement over the 0/3 baseline; the gate works.

---

## Changed files (branch `fix/tdd-default-and-review-gate`)

D1 (commit `ad42469`):
- `skills/writing-plans/SKILL.md` — new "## TDD Is the Default; Waivers Are Explicit" subsection.
- `skills/subagent-driven-development/implementer-prompt.md` — 3 lines: job-list step 2, self-review line, report TDD-Evidence line.
- `skills/subagent-driven-development/SKILL.md:437` — integration one-liner + "unless the task brief explicitly waives it".
- `skills/subagent-driven-development/task-reviewer-prompt.md` — Tests note now waiver-aware.

D2 (commit `d5057a1`):
- `skills/finishing-a-development-branch/SKILL.md` — review-status check before the Step 4 menu + Red Flags "Surface review status before presenting options" bullet.

Waiver token uses em-dash U+2014 everywhere (`TDD: waived — <reason>`), verified at
codepoint level in the D1 per-task review.

## Note on deployment

`docs/marketplace/superpowers` is a **symlink** to `superpowers-j2v.git` — editing
the source updates the active plugin's files directly; `/reload-plugins` picks up
the change. Integration (merge) is deliberately left to
`superpowers:finishing-a-development-branch` after human review.
