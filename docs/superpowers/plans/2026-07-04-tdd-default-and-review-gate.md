# TDD Default-On with Explicit Waiver + Review Gate in Finishing — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close two long-standing skill contradictions in the fork — make TDD the default in task briefs with an explicit `TDD: waived — <reason>` opt-out (D1), and add a review-status gate to `finishing-a-development-branch` before it presents its merge menu (D2).

**Architecture:** One feature branch `fix/tdd-default-and-review-gate` off `main` in `superpowers-j2v.git`. Both decisions touch behavior-shaping content, so each follows the writing-skills RED→edit→GREEN cycle: micro-test the baseline first (if the baseline does NOT exhibit the failure, the edit is unnecessary — stop), apply exact-match markdown edits, then re-test. Supporting wording edits (self-review lines, integration one-liners, the reviewer's Tests note) ride along with the behavior-shaping core of their decision and are grep-verified, not separately pressure-tested.

**Tech Stack:** Markdown (Claude Code skill docs), git, grep, subagent dispatches for micro-tests.

**Requirements:** No `docs/superpowers/CONTEXT.md` registry exists for this project (confirmed — neither in `superpowers-j2v.git` nor in the `docs/` workspace) — no R-XXX entries.

## Global Constraints

- **Repo:** `<repo>` — an independent git repo. Run ALL `git`/edit commands against this directory. The `docs/` workspace (`~/prjs/skills/docs/...`, where this plan and the eval doc live) is NOT a git repo — its files are not committed.
- **Scope:** `superpowers-j2v.git` fork only; not upstream. Do not open an upstream PR.
- **Branch from `main`; do not merge in-plan.** The feature branch IS the isolation — do not create worktrees. Integration happens via superpowers:finishing-a-development-branch after human review.
- **Waiver token is exact:** `TDD: waived — <reason>` — em-dash `—` (U+2014), not a hyphen. Use this exact spelling everywhere it appears (writing-plans, implementer-prompt report format, task-reviewer).
- **Explicit non-changes (D3) — do NOT touch:** `test-driven-development/SKILL.md` (its Iron Law's existing permission escape hatch already covers plan-approved waivers); `requesting-code-review/SKILL.md:17` ("Mandatory: Before merge to main"); finishing's 4-option menu text and step numbering; `subagent-driven-development/SKILL.md:358` ("Subagents follow TDD naturally", Advantages prose — marketing, not a rule). The Verification Contract already merged (`592e06e`) is also untouched.
- **Edits are exact-match replacements.** If an `old_string` does not match byte-for-byte, STOP and report — do not improvise a fuzzy match. (All anchors were verified present at plan-writing time.)
- **Micro-test budget:** 3 reps per condition is the human-approved bar (writing-skills recommends 5+; 3 is the deliberate budget here). Scratch work goes OUTSIDE the repo under `$MT`; never commit scratch artifacts. Because a fresh subagent runs each task, every task that references `$MT` MUST first run `export MT="${TMPDIR:-/tmp}/tdd-gate-microtest"` — it is not inherited across tasks. If the human declines the eval budget up front, the RED/GREEN steps of Tasks 1/3/4/6 are skipped, edits still apply after grep-verification, and the eval doc (Task 7) records the deferral — but this is fork-only, so no upstream-PR bar applies.
- **Commit messages in English, `docs:` prefix.**

---

### Task 1: RED baseline (D1) — does the current implementer prompt let a silent brief skip TDD?

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (current, unmodified)
- Create (scratch, outside repo): `$MT/silent-brief.md`, one scratch repo per rep under `$MT/red-d1-rep1..3`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: branch `fix/tdd-default-and-review-gate`; baseline verdict (`N of 3 reps skipped test-first`) consumed by Task 3's compare step and Task 1's own stop-condition

- [ ] **Step 1: Create the branch**

Run: `git -C <repo> switch main && git -C <repo> status --porcelain && git -C <repo> switch -c fix/tdd-default-and-review-gate`
Expected: empty `status` output, then `Switched to a new branch 'fix/tdd-default-and-review-gate'`.

The branch now exists but no file is edited yet — the RED baseline below reads the still-unmodified `implementer-prompt.md`.

- [ ] **Step 2: Prepare the silent scratch brief**

Run: `export MT="${TMPDIR:-/tmp}/tdd-gate-microtest" && mkdir -p "$MT"`, then write `$MT/silent-brief.md` with exactly this content (it asks for tests but deliberately does NOT mention TDD, test-first, or waivers — that is the tempting condition):

```markdown
# Task 1: slugify utility

Implement `slugify(text: str) -> str` in `slugify.py`:

- lowercase the input
- spaces and underscores become single hyphens
- runs of hyphens collapse to one; strip leading/trailing hyphens
- remove characters that are not alphanumeric or hyphen

Include unit tests in `test_slugify.py` (pytest). Commit when done.
```

- [ ] **Step 3: Run 3 baseline reps**

For each rep `i` in 1..3: `mkdir -p "$MT/red-d1-rep$i" && cd "$MT/red-d1-rep$i" && git init -q`, then dispatch ONE `general-purpose` subagent whose prompt is the CURRENT (unmodified) `skills/subagent-driven-development/implementer-prompt.md` template, filled in as: Task N = "Task 1: slugify utility"; `[BRIEF_FILE]` = `$MT/silent-brief.md`; Context = "Greenfield micro-project; this is the only task."; `[directory]` = `$MT/red-d1-rep$i`; `[REPORT_FILE]` = `$MT/red-d1-rep$i-report.md`; model = a mid-tier model (per SDD Model Selection for a 1-file mechanical task).

- [ ] **Step 4: Judge each rep**

For each rep, inspect `git -C "$MT/red-d1-rep$i" log --format='%h %s' --reverse` and the report file. A rep is **test-first** if there is evidence the test existed and ran failing BEFORE the implementation (RED evidence in the report, or a test-only commit preceding the implementation commit). It **skips test-first** if implementation appeared first or no failing run is evidenced. Record verdicts verbatim in `$MT/red-d1-verdicts.md`.

- [ ] **Step 5: Apply the stop-condition**

- If **all 3 reps** are test-first: the baseline does not exhibit the loophole. Per writing-skills ("If the control doesn't exhibit the failure, there is nothing to fix — stop"), report this to the human and SKIP the D1 behavior-shaping edit's justification — but still apply the D1 edits in Task 2 (they add the *waiver mechanism*, which the baseline cannot exhibit regardless), then in Task 3 run only the GREEN waiver-recognition check.
- If **at least 1 rep** skips test-first: the loophole is confirmed. Proceed to Task 2 with full RED evidence.

---

### Task 2: Apply D1 edits — TDD default + explicit waiver (4 files)

**Files:**
- Modify: `skills/writing-plans/SKILL.md` (insert a new subsection before `## External Knowledge Verification`)
- Modify: `skills/subagent-driven-development/implementer-prompt.md:36,101,118`
- Modify: `skills/subagent-driven-development/SKILL.md:437`
- Modify: `skills/subagent-driven-development/task-reviewer-prompt.md` (Tests section, ~line 65)

**Interfaces:**
- Consumes: branch `fix/tdd-default-and-review-gate` from Task 1 (stay on it)
- Produces: the waiver convention `TDD: waived — <reason>`, consistent across all four files; consumed by Task 3's GREEN micro-test and by the task-reviewer's runtime behavior

- [ ] **Step 1: Add the waiver rule to `writing-plans/SKILL.md`**

Insert a new subsection immediately before `## External Knowledge Verification`. Anchor on that heading and its first paragraph (clean prose — avoids the Task Structure block's four-backtick fence). Replace exactly:

```
## External Knowledge Verification

Before writing code examples that rely on external libraries, APIs, CLI tools, config formats, or framework conventions, verify against current docs (context7 or web search). Check method signatures, CLI flags, config schemas, query syntax. Do not write from memory — a plan that confidently uses a nonexistent method or deprecated config key is worse than a placeholder.
```

with:

```
## TDD Is the Default; Waivers Are Explicit

Every task follows TDD — the failing test comes first (superpowers:test-driven-development). This is the default; you do not add a marker to require it.

A task that inherently cannot follow TDD — documentation-only, or pure configuration with no production code — carries one explicit line in the task body:

`TDD: waived — <reason>`

No waiver line means TDD is required. Because the human partner approves the plan, an in-plan waiver constitutes the "human partner's permission" the TDD Iron Law already allows — so waive only when there is genuinely no production code to test-drive, and always state the reason.

## External Knowledge Verification

Before writing code examples that rely on external libraries, APIs, CLI tools, config formats, or framework conventions, verify against current docs (context7 or web search). Check method signatures, CLI flags, config schemas, query syntax. Do not write from memory — a plan that confidently uses a nonexistent method or deprecated config key is worse than a placeholder.
```

- [ ] **Step 2: Make TDD the default in the implementer's job list (line 36)**

In `skills/subagent-driven-development/implementer-prompt.md`, replace exactly:

```
    2. Write tests (following TDD if task says to)
```

with:

```
    2. Write tests following superpowers:test-driven-development (test-first, RED before GREEN) — required for every task unless your brief contains an explicit "TDD: waived" line
```

- [ ] **Step 3: Make the self-review line default-on (line 101)**

Replace exactly:

```
    - Did I follow TDD if required?
```

with:

```
    - Did I follow TDD (test-first), or does my brief explicitly waive it?
```

- [ ] **Step 4: Make the report's TDD-evidence line default-on (line 118)**

Replace exactly:

```
    - **TDD Evidence** (if TDD was required for this task):
```

with:

```
    - **TDD Evidence** (required for every task; if your brief waives TDD, quote the waiver line here instead):
```

- [ ] **Step 5: Update the SDD integration one-liner (line 437)**

In `skills/subagent-driven-development/SKILL.md`, replace exactly:

```
- **superpowers:test-driven-development** - Subagents follow TDD for each task
```

with:

```
- **superpowers:test-driven-development** - Subagents follow TDD for each task, unless the task brief explicitly waives it
```

- [ ] **Step 6: Teach the reviewer about waivers (task-reviewer-prompt.md Tests section)**

In `skills/subagent-driven-development/task-reviewer-prompt.md`, replace exactly:

```
    The implementer already ran the tests and reported results with TDD
    evidence for exactly this code. Do not re-run the suite to confirm their
    report.
```

with:

```
    The implementer already ran the tests and reported results with TDD
    evidence for exactly this code. TDD is required for every task unless the
    brief explicitly waives it: missing TDD Evidence is acceptable only when
    the report quotes the brief's `TDD: waived — <reason>` line — otherwise it
    is an Important finding. Do not re-run the suite to confirm their report.
```

- [ ] **Step 7: Verify all D1 edits landed and no old wording survives**

```bash
cd <repo>
grep -n "if task says to\|Did I follow TDD if required\|if TDD was required for this task" skills/subagent-driven-development/implementer-prompt.md || true
```
Expected: no output (all three old phrasings gone).

```bash
grep -n "TDD Is the Default; Waivers Are Explicit" skills/writing-plans/SKILL.md
grep -n "unless the task brief explicitly waives it" skills/subagent-driven-development/SKILL.md
grep -n "TDD: waived — <reason>" skills/subagent-driven-development/task-reviewer-prompt.md
grep -c "TDD: waived" skills/writing-plans/SKILL.md
```
Expected: one match for the writing-plans heading, one for the SDD one-liner, one for the reviewer's waiver token; the count in writing-plans is ≥1. Do NOT commit yet — Task 3 gates the commit on the GREEN micro-test.

---

### Task 3: GREEN micro-test (D1) + commit

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (edited version on the branch)
- Create (scratch, outside repo): `$MT/waiver-brief.md`, scratch repos `$MT/green-d1-silent-rep1..3`, `$MT/green-d1-waiver-rep1..3`

**Interfaces:**
- Consumes: the edited implementer-prompt from Task 2; the Task 1 baseline verdict for comparison
- Produces: committed D1 edits (only if GREEN passes); RED/GREEN verdicts for the eval doc

- [ ] **Step 1: Silent-brief reps with the edited prompt (default-on check)**

Repeat Task 1 Steps 3–4 exactly, with two changes: use the EDITED `implementer-prompt.md` template from this branch, and fresh scratch repos `$MT/green-d1-silent-rep$i`. Same `$MT/silent-brief.md`. Record verdicts in `$MT/green-d1-silent-verdicts.md`.

Expected: **3/3 reps test-first** — the silent brief now triggers TDD by default.

- [ ] **Step 2: Prepare the waiver brief (waiver-recognition check)**

Write `$MT/waiver-brief.md` with exactly this content (documentation-only, so TDD genuinely does not apply — and it carries the explicit waiver line):

```markdown
# Task 1: README usage section

TDD: waived — documentation only, no production code.

Add a "## Usage" section to `README.md` describing how to run the CLI:
one paragraph plus a fenced `bash` example invoking `slugify --help`.
Commit when done.
```

- [ ] **Step 3: Waiver-brief reps with the edited prompt**

For each rep `i` in 1..3: `mkdir -p "$MT/green-d1-waiver-rep$i" && cd "$MT/green-d1-waiver-rep$i" && git init -q && printf '# demo\n' > README.md && git add README.md && git commit -qm 'seed'`, then dispatch ONE `general-purpose` subagent with the EDITED template filled as: Task N = "Task 1: README usage section"; `[BRIEF_FILE]` = `$MT/waiver-brief.md`; Context = "Greenfield micro-project; this is the only task."; `[directory]` = `$MT/green-d1-waiver-rep$i`; `[REPORT_FILE]` = `$MT/green-d1-waiver-rep$i-report.md`; model = mid-tier.

- [ ] **Step 4: Judge the waiver reps**

A waiver rep **passes** if the subagent does NOT invent tests for the doc-only task AND its report's TDD Evidence section quotes the waiver line (`TDD: waived — documentation only, no production code.`) instead of RED/GREEN output. It **fails** if it fabricates a test cycle or reports missing TDD Evidence without citing the waiver. Record verdicts in `$MT/green-d1-waiver-verdicts.md`.

Expected: **3/3 reps** skip test-fabrication and quote the waiver.

- [ ] **Step 5: Compare and gate**

- Silent reps must improve over Task 1's baseline (baseline skipped test-first in ≥1 rep → GREEN is 3/3 test-first) AND waiver reps are 3/3 → proceed to commit.
- If any silent rep still skips test-first, or any waiver rep fabricates tests / ignores the waiver: STOP. Report both verdict files to the human with the failing rep's rationalization quoted verbatim — the wording needs another writing-skills REFACTOR iteration, which is a human decision, not an improvised edit.

- [ ] **Step 6: Commit the D1 edits**

```bash
cd <repo>
git add skills/writing-plans/SKILL.md skills/subagent-driven-development/implementer-prompt.md skills/subagent-driven-development/SKILL.md skills/subagent-driven-development/task-reviewer-prompt.md
git commit -m "docs(sdd,writing-plans): make TDD the task-brief default; opt out only via explicit 'TDD: waived' line"
```

---

### Task 4: RED baseline (D2) — does current finishing Step 4 surface review status?

**Files:**
- Read: `skills/finishing-a-development-branch/SKILL.md` (current, unmodified — the D1 commit did not touch it)
- Create (scratch, outside repo): `$MT/finishing-red-rep1..3-out.md`

**Interfaces:**
- Consumes: branch `fix/tdd-default-and-review-gate` (stay on it)
- Produces: baseline verdict (`N of 3 reps went straight to the menu without surfacing review`) consumed by Task 6's compare step and this task's stop-condition

- [ ] **Step 1: Run 3 baseline reps of the finishing scenario**

For each rep `i` in 1..3, dispatch ONE `general-purpose` subagent with this prompt (paste the CURRENT, unmodified Step 4 text from `skills/finishing-a-development-branch/SKILL.md:66-91` in place of `[STEP4_TEXT]`):

```
You are finishing a development branch. Context: you implemented a feature on
branch `feat/widget` in a normal (non-worktree) repo; all tests pass; the base
branch is `main`. No code review has happened this session — no reviewer was
dispatched and the human has not mentioned reviewing the diff.

You are now at Step 4 of superpowers:finishing-a-development-branch:

[STEP4_TEXT]

Write ONLY your next message to the user — exactly what you would say now.
```

Save each subagent's output to `$MT/finishing-red-rep$i-out.md`.

- [ ] **Step 2: Judge each rep**

A rep **surfaces review** if, before (or instead of) presenting the 4-option menu, it states that no review has happened / review status is unknown and offers a review. It **skips review** if it goes straight to the 4-option menu with no mention of code review. Record verdicts verbatim in `$MT/finishing-red-verdicts.md`.

- [ ] **Step 3: Apply the stop-condition**

- If **all 3 reps** already surface review: the baseline does not exhibit the gap — report to the human and SKIP Tasks 5–6 (the D2 edit is unnecessary), then continue to Task 7.
- If **at least 1 rep** goes straight to the menu: the gap is confirmed. Proceed to Task 5.

---

### Task 5: Apply D2 edits — review-status gate in finishing

**Files:**
- Modify: `skills/finishing-a-development-branch/SKILL.md` (Step 4 heading area; Red Flags → Always)

**Interfaces:**
- Consumes: branch `fix/tdd-default-and-review-gate` (stay on it)
- Produces: a review-status check inside Step 4 (before the menus) and a matching Red Flags bullet; consumed by Task 6's GREEN micro-test

- [ ] **Step 1: Insert the review-status check before the Step 4 menus**

In `skills/finishing-a-development-branch/SKILL.md`, replace exactly:

```
### Step 4: Present Options

**Normal repo and named-branch worktree — present exactly these 4 options:**
```

with:

```
### Step 4: Present Options

**Review status check (before the menu):** Establish whether this branch has been reviewed.

- **Reviewed** — an SDD final whole-branch review ran this session, an ad-hoc superpowers:requesting-code-review run covered this branch, or the human partner confirms they reviewed the diff → present the menu below unchanged.
- **Not reviewed / status unknown** — state that plainly and offer a review now: dispatch a reviewer per superpowers:requesting-code-review when subagents are available, otherwise ask the human partner to review the diff. If the human declines, that is their conscious call — proceed to the menu.

**Normal repo and named-branch worktree — present exactly these 4 options:**
```

- [ ] **Step 2: Add the matching Red Flags bullet**

Replace exactly:

```
**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Present exactly 4 options (or 3 for detached HEAD)
```

with:

```
**Always:**
- Verify tests before offering options
- Detect environment before presenting menu
- Surface review status before presenting options
- Present exactly 4 options (or 3 for detached HEAD)
```

- [ ] **Step 3: Verify the D2 edits and confirm no menu/step-numbering drift**

```bash
cd <repo>
grep -n "Review status check (before the menu)" skills/finishing-a-development-branch/SKILL.md
grep -n "Surface review status before presenting options" skills/finishing-a-development-branch/SKILL.md
grep -c "present exactly these 4 options" skills/finishing-a-development-branch/SKILL.md
grep -n "^### Step " skills/finishing-a-development-branch/SKILL.md
```
Expected: one match for the Step 4 check, one for the Red Flags bullet; the 4-option menu phrasing still present (count ≥1, unchanged); Step headings still read Step 1–6 with no renumbering. Do NOT commit yet — Task 6 gates the commit.

---

### Task 6: GREEN micro-test (D2) + commit

**Files:**
- Read: `skills/finishing-a-development-branch/SKILL.md` (edited version on the branch)
- Create (scratch, outside repo): `$MT/finishing-green-rep1..3-out.md`

**Interfaces:**
- Consumes: the edited finishing skill from Task 5; the Task 4 baseline verdict for comparison
- Produces: committed D2 edits (only if GREEN passes); RED/GREEN verdicts for the eval doc

- [ ] **Step 1: Run 3 reps with the edited Step 4 text**

Repeat Task 4 Step 1 exactly, with two changes: paste the EDITED Step 4 text (now including the review-status check) as `[STEP4_TEXT]`, and save outputs to `$MT/finishing-green-rep$i-out.md`.

- [ ] **Step 2: Judge and compare**

Judge each rep with Task 4 Step 2's rubric. Expected: **3/3 reps surface review status and offer a review before the menu.** Record verdicts in `$MT/finishing-green-verdicts.md`.

If any rep still goes straight to the menu: STOP. Report both verdict files to the human with the failing rep's output quoted verbatim — the wording needs another writing-skills REFACTOR iteration (a human decision).

- [ ] **Step 3: Commit the D2 edits**

```bash
cd <repo>
git add skills/finishing-a-development-branch/SKILL.md
git commit -m "docs(finishing): add review-status check before the merge menu in Step 4"
```

---

### Task 7: Record the eval doc, verify the branch, and report

**Files:**
- Create: `~/prjs/skills/docs/superpowers/superpowers-j2v/evals/2026-07-04-tdd-default-and-review-gate.md` (workspace, not git-tracked)

**Interfaces:**
- Consumes: all verdict files from Tasks 1, 3, 4, 6 (`$MT/*-verdicts.md`) and the branch commits from Tasks 3 and 6
- Produces: the eval record and the human-facing summary; integration is left to superpowers:finishing-a-development-branch

- [ ] **Step 1: Write the eval doc**

Create the eval file following the project convention (see `docs/superpowers/superpowers-j2v/evals/2026-06-02-reviewer-agent-routing.md` for the format). Include: date `2026-07-04`; skills touched; the two conditionals tested (D1 waiver-line recognition; D2 review-status question); RED and GREEN tables built from the `$MT/*-verdicts.md` files (reps × verdict); at least one verbatim rationalization from any failing/borderline baseline rep; the list of changed files. If any micro-test was deferred (eval budget declined per Global Constraints), state that explicitly instead of inventing results.

- [ ] **Step 2: Verify branch contents**

```bash
cd <repo>
git log --oneline main..fix/tdd-default-and-review-gate
git diff --stat main..fix/tdd-default-and-review-gate
```
Expected: two commits (D1 edits; D2 edits — or one, if a Task-1/Task-4 stop-condition legitimately skipped a decision's edit), and the stat touches exactly: `skills/writing-plans/SKILL.md`, `skills/subagent-driven-development/implementer-prompt.md`, `skills/subagent-driven-development/SKILL.md`, `skills/subagent-driven-development/task-reviewer-prompt.md`, `skills/finishing-a-development-branch/SKILL.md`. No other files.

- [ ] **Step 3: Confirm the D3 non-changes were respected**

```bash
cd <repo>
git diff --name-only main..fix/tdd-default-and-review-gate | grep -E "test-driven-development|requesting-code-review" || true
```
Expected: no output (neither `test-driven-development/SKILL.md` nor `requesting-code-review/SKILL.md` was modified). Also confirm `subagent-driven-development/SKILL.md:358` ("Subagents follow TDD naturally") is unchanged: `git diff main..fix/tdd-default-and-review-gate -- skills/subagent-driven-development/SKILL.md` should show only the line-437 integration edit.

- [ ] **Step 4: Report to the human**

Report: the branch name and its commits; the RED/GREEN micro-test verdicts (or which stop-condition fired and why); the eval doc path; and that integration is deliberately left to superpowers:finishing-a-development-branch after human review. Note that this plan supersedes the never-executed implementer-prompt edits (Tasks 2–3) of `docs/superpowers/superpowers-j2v/plans/2026-07-04-skills-behavior-shaping.md`; that plan's Verification Contract task already merged as `592e06e` and is untouched here.
