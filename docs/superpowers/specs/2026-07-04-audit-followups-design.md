# Audit Follow-Ups: TDD Cadence Note, Review-Feedback Pointer, Conditional Micro-Tests, Frontmatter Descriptions — Design

**Date:** 2026-07-04
**Status:** Approved (design)
**Scope:** `superpowers-j2v.git` fork only; not upstream
**Affected skills:** `test-driven-development`, `requesting-code-review`, `project-registry`, `brainstorming`; plus micro-test coverage for the conditionals shipped in `ad42469`/`d5057a1`

---

## 1. Context & Problem

The 2026-07-04 consistency audit left four items that affect execution quality, speed, or skill effectiveness (numbering continues the audit's):

- **#5 (speed):** `test-driven-development/SKILL.md` Verify GREEN mandates "Other tests still pass" after *every* GREEN, while `implementer-prompt.md:47-48` says "run the full suite once before committing". An implementer loads both; the stricter reading wins → full suite per GREEN cycle = tokens + wall-clock on every SDD task. The fast cadence is the deliberate, newer side (upstream `e08ad06`, 2026-06-09). Artifact quality is guarded regardless by three gates: commit-time full suite, the report's honest test summary (VBC), and finishing's full-suite run.
- **#4 (quality):** the conditionals shipped today — the `TDD: waived` brief line (`ad42469`) and the finishing review-status check (`d5057a1`) — are behavior-shaping wording that was never tested. Untested wording risks being non-binding (writing-skills: interpretation variance is the norm).
- **#8 (quality):** `receiving-code-review` has zero inbound references; the anti-performative-agreement discipline never activates when review feedback arrives.
- **#11 (effectiveness):** two frontmatter descriptions violate the repo's own SDO convention. `project-registry`'s description summarizes its operations and callers — the documented SDO trap (agents execute the summary instead of reading the skill). `brainstorming`'s description ("You MUST use this…") violates "Use when…"/third-person, but its imperative form plausibly carries the auto-trigger that the repo's acceptance test ("Let's make a react todo list") depends on.

## 2. Decisions

### D1 (#5) — Scoping note in TDD skill, prompt unchanged

**Decision:** add one scoping sentence to the Verify GREEN section of `test-driven-development/SKILL.md`: in subagent workflows the dispatch prompt sets full-suite cadence (focused test per cycle, full suite once before commit). The iron law and RED-GREEN steps are untouched — this scopes where the cadence rule is defined, it does not weaken what must be verified.

**Rejected alternatives:**
- *Per-GREEN full suite everywhere* — upstream already paid for and retired this (minutes × cycles × tasks); artifact quality is protected by the three downstream gates.
- *Runtime-conditional cadence* ("suite < ~1 min → run per GREEN") — valid form (observable predicate), but touches the pressure-tested prompt and needs its own micro-tests. Deferred until evals show mid-task regressions actually hurt (YAGNI).

**Accepted trade-off:** later in-task regression attribution and sunk-cost rationalization pressure at commit time ("pre-existing failure"). Mitigated by right-sized tasks, the focused test per cycle, and the report contract (a red suite cannot be honestly reported as passing).

**Change:** `test-driven-development/SKILL.md`, Verify GREEN section — one added sentence. Micro-test the wording before adopting (pressure-tested content; see D3 protocol).

### D2 (#8) — Single pointer to receiving-code-review

**Decision:** `requesting-code-review/SKILL.md`, section "3. Act on feedback" gains:
`**REQUIRED SUB-SKILL:** Use superpowers:receiving-code-review before implementing fixes`.

**Only there.** SDD's per-task loop has its own contract (findings route back to the implementer), and SDD's final whole-branch review already goes through `requesting-code-review` — one pointer covers both paths. No SDD edit.

### D3 (#4) — Micro-tests for the shipped conditionals

**Decision:** validate the `ad42469`/`d5057a1` wording with subagent micro-tests per the writing-skills protocol. Full `evals/` harness runs are a follow-up, out of scope here.

| Test | Arms | Expected |
|---|---|---|
| T1: brief **contains** `TDD: waived — <reason>` | new prompt | implementer skips TDD, quotes the waiver line in the report |
| T2: brief **silent** on TDD (the closed loophole — key test) | new vs old ("if task says to") vs no-guidance control | new: RED before GREEN; old: expected failure (production code without a failing test) |
| T3: report missing TDD Evidence | task-reviewer, with vs without a quoted waiver | flags the gap; accepts only with the quoted waiver line |
| T4: finishing reaches Step 4, no review evidence in context | new vs old Step 4 text | new: states review status and offers a review; old: straight to the menu |

**Protocol (per writing-skills):** fresh context per sample; system prompt = the full realistic context (entire prompt template / skill file, not the clause in isolation); 5+ reps per arm; a no-guidance control arm where marked; manually read every flagged sample (template echoes masquerade as hits); interpretation variance across reps is itself a fail signal.

**Pass criteria:** new-wording arms converge on the expected behavior across reps; T2's old arm reproduces the original failure (confirming the test can fail). A failing new arm → tighten wording and re-run; do not ship a conditional whose arm did not converge.

### D4 (#11) — Frontmatter descriptions

**D4a — project-registry (unconditional):** replace the description with:

> `Use when another skill directs you to run a registry operation on docs/superpowers/CONTEXT.md — the AI-workspace index of in-progress specs, R-XXX constraints, and F-XXX features. Not user-invocable directly; project facts (architecture, tech stack) live in the source repo, not here.`

Removes the operation-by-caller summary (the SDO trap); keeps the keywords (CONTEXT.md, R-XXX, F-XXX), the not-user-invocable marker, and the responsibility boundary.

**D4b — brainstorming (gated by A/B trigger test):** candidate description:

> `Use when starting any creative work — creating features, building components, adding functionality, or modifying behavior — before writing any code or invoking implementation skills.`

**Gate:** discriminator simulation. System prompt = the full skill-description list as a real session sees it; tasks split into a trigger set ("Let's make a react todo list" — the repo acceptance test, "add dark mode to the app", "build a CLI tool for X") and a non-trigger set ("fix this bug", "explain this code", "why is this test flaky"); 5+ reps per task per arm (old vs candidate). **Acceptance: zero regression on the trigger set (specifically 100% on the acceptance-test prompt) and no increase in false positives on the non-trigger set.** On regression: keep the current description and record it in the skill file as a deliberate, tested exception to the "Use when…" convention.

### D5 — Explicit non-changes

- `implementer-prompt.md` cadence text — stays (D1 scopes the TDD skill to it, not vice versa).
- SDD files — no new pointers (D2 rationale).
- Full `evals/` harness scenarios — follow-up, not part of this work.
- The remaining audit soft items (#9 terminology, #10 TodoWrite, #12-#15) — separate work, no behavioral urgency established.

## 3. Execution Order

1. D3 first (T1-T4): today's shipped conditionals get validated before more wording lands on top of them.
2. D1 + D2 (small edits; D1's sentence micro-tested alongside the D3 batch).
3. D4a, then D4b's gate run; D4b ships only on a clean gate.

## 4. Traceability

Audit source: consistency analysis of 2026-07-04 (post-upstream-v6.1.1 merge `2ad04c3`); prior fixes `d4ee28f` (audit #1, #2, #6, #7) and specs shipped as `ad42469`/`d5057a1` (audit #3, #4 — TDD-default + review gate, spec in the `docs/` workspace repo). No `docs/superpowers/CONTEXT.md` registry exists; no R-XXX registration performed.
