# TDD Default-On with Explicit Waiver + Review Gate in Finishing — Design

**Date:** 2026-07-04
**Status:** Approved (design)
**Scope:** `superpowers-j2v.git` fork only; not upstream
**Affected skills:** `subagent-driven-development` (SKILL.md, implementer-prompt.md, task-reviewer-prompt.md), `writing-plans`, `finishing-a-development-branch`

---

## 1. Context & Problem

The 2026-07-04 consistency audit of the fork's skills (run after the upstream v6.1.1 merge `2ad04c3`) surfaced two contradictions that a mechanical doc-sync could not resolve — both required a design decision:

**Contradiction #4 — TDD unconditional vs conditional.**
`test-driven-development/SKILL.md` states an iron law ("NO PRODUCTION CODE WITHOUT A FAILING TEST FIRST", exceptions only with the human partner's permission), and `subagent-driven-development/SKILL.md:437` claims "Subagents follow TDD for each task". But the dispatch template SDD actually uses — `implementer-prompt.md` — makes TDD conditional: "Write tests (following TDD **if task says to**)" (line 36), echoed at lines 101 and 118. A task brief that is silent about TDD legitimately produces production code with no failing test first. The conditional wording dates to the upstream initial commit; the contradiction is long-standing, not a merge artifact.

**Contradiction #3 — review mandate without an enforcement point.**
`requesting-code-review/SKILL.md:17` declares review "Mandatory: Before merge to main", but `finishing-a-development-branch` — the skill that executes the merge and the terminal step of every workflow path — gates the merge only on passing tests. Via SDD the mandate is satisfied upstream (final whole-branch review precedes finishing), but via `executing-plans` (the no-subagent path) and ad-hoc work, nothing surfaces review status before the merge happens.

### Goal

Close both gaps with surgical edits that (a) keep the TDD iron law intact — the waiver path routes through human approval, (b) give the review mandate an enforcement point without adding friction to paths where review already happened, and (c) leave pressure-tested content (`test-driven-development/SKILL.md`, the 4-option finishing menu) untouched.

## 2. Decisions

### D1 — TDD is the default in task briefs; an explicit waiver line is the only opt-out

**Decision:** absence of a marker in the task brief = TDD required. A task that inherently cannot follow TDD (doc-only, pure configuration) carries an explicit line in the plan task: `TDD: waived — <reason>`. Because the human partner approves the plan, an in-plan waiver constitutes the "human partner's permission" that the TDD iron law already allows — the law itself needs no edit.

**Rejected alternatives:**
- *TDD always, no exceptions* — stiffens the E03 transcription mode unnecessarily and removes the plan's ability to make a deliberate call for tasks with no production code.
- *Keep conditional, soften the TDD skill* — preserves the prompt's status quo but weakens pressure-tested iron-law content; high behavioral-regression risk.

**Interaction with E03 (cheapest-tier transcription):** unaffected. When the plan carries complete code, it carries the tests too, so RED-GREEN is mechanically followable (paste test → watch fail → paste implementation). The waiver is reserved for tasks with no production code at all.

**Changes:**

| File | Location | Change |
|---|---|---|
| `writing-plans/SKILL.md` | task template guidance | New rule: a task that inherently cannot follow TDD gets an explicit `TDD: waived — <reason>` line. No line = TDD required. |
| `subagent-driven-development/implementer-prompt.md` | line 36 ("Your Job") | "Write tests (following TDD if task says to)" → TDD is the default; skip only if the brief contains an explicit `TDD: waived` line. |
| `subagent-driven-development/implementer-prompt.md` | line 101 (self-review) | "Did I follow TDD if required?" → default-on phrasing: followed TDD, or the brief explicitly waives it. |
| `subagent-driven-development/implementer-prompt.md` | line 118 (report format) | "**TDD Evidence** (if TDD was required for this task)" → required always, unless waived — in which case the report quotes the waiver line. |
| `subagent-driven-development/SKILL.md` | line 437 (integrations) | "Subagents follow TDD for each task" → "… unless the task brief explicitly waives it". |
| `subagent-driven-development/task-reviewer-prompt.md` | line 66 area | Reviewer knows about waivers: missing TDD Evidence is acceptable only when the report quotes the brief's waiver line. |

### D2 — Lightweight review-status gate in finishing, human adjudicates

**Decision:** `finishing-a-development-branch` Step 4 (Present Options) gains a pre-menu check. Observable predicate — evidence of a review of this branch:

- review happened (SDD final whole-branch review this session, an ad-hoc `requesting-code-review` run, or the human partner confirms their own review) → present the menu unchanged;
- no review / status unknown → state it plainly and offer one now: dispatch a reviewer per `superpowers:requesting-code-review` when subagents are available, otherwise ask the human partner to review the diff. Declining is the human's conscious call — proceed to the menu.

**Rejected alternatives:**
- *Hard gate (block merge until review evidence)* — "did a review happen" is not reliably verifiable across sessions; adds friction to every finishing, including post-SDD where review already ran.
- *Soften the mandate, no gate* — zero friction but the ad-hoc path keeps a paper-only mandate.

**Placement rationale:** inside Step 4, before the menus — no step renumbering (Step 6 is referenced from four places), and the 4-option menu structure (pressure-tested, "present exactly these 4 options") stays untouched.

**Changes:**

| File | Location | Change |
|---|---|---|
| `finishing-a-development-branch/SKILL.md` | Step 4, before the menus | "Review status check" paragraph per the mechanism above. |
| `finishing-a-development-branch/SKILL.md` | Red Flags → Always | New bullet: "Surface review status before presenting options". |

### D3 — Explicit non-changes

- `test-driven-development/SKILL.md` — untouched; the iron law's existing permission escape hatch covers plan-approved waivers.
- `requesting-code-review/SKILL.md:17` "Mandatory: Before merge to main" — stays; D2 gives it an enforcement point, and a conscious human skip is consistent with "human partner decides".
- Finishing's 4-option menu and step numbering — untouched.
- `subagent-driven-development/SKILL.md:358` ("Subagents follow TDD naturally", Advantages prose) — left as-is; marketing prose, not a normative rule.

## 3. Testing Note

`implementer-prompt.md` and the finishing Step 4 flow are behavior-shaping content. Per `writing-skills`, wording changes should be micro-tested (fresh-context reps against a no-guidance control) before being trusted; the fork's eval harness (`evals/`) is the final gate. This spec records the intended semantics; the implementation plan should include at least a micro-test of the two new conditionals (waiver line recognition; review-status question) if eval time is available.

## 4. Requirement Traceability

No `docs/superpowers/CONTEXT.md` registry exists for this project (neither in `superpowers-j2v.git` nor in the `docs/` workspace repo); no R-XXX registration performed. Source audit trail: consistency-fix series merged as `d4ee28f` in `superpowers-j2v.git` (fixes #1, #2, #6, #7); this spec covers the remaining #3 and #4.
