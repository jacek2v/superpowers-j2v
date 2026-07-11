# Skills Consistency — Behavior-Shaping Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Close the conditional-TDD loophole in the implementer prompt and reconcile SDD's trust model with verification-before-completion — the two changes that alter agent behavior and therefore need testing per superpowers:writing-skills.

**Architecture:** Two feature branches created from `main` in `superpowers-j2v.git`. Branch `fix/implementer-tdd-default` changes a discipline rule, so it follows the writing-skills RED-GREEN cycle: micro-test the baseline first (if the baseline does NOT exhibit the failure, the change is unnecessary — stop), then edit, then re-test. Branch `fix/vbc-sdd-trust-note` adds a clarifying section that documents already-required evidence; it gets a wording review, not a pressure test.

**Tech Stack:** Markdown (Claude Code skill docs), git, grep, subagent dispatches for micro-tests.

**Requirements:** No CONTEXT.md registry exists for this project — none.

## Global Constraints

- Repo: `<repo>` — an independent git repo. Run ALL commands from this directory unless a step says otherwise.
- Create every branch from `main`. Do NOT merge any branch in this plan — integration happens per-branch via superpowers:finishing-a-development-branch after human review.
- Feature branches ARE the isolation for this plan; do not create worktrees.
- These edits touch behavior-shaping content. Per the repo's CLAUDE.md, such changes need evidence — the micro-tests in Task 1/2 are the minimum bar (writing-skills recommends 5+ reps; 3 reps here is the human-approved budget). Do not skip them.
- Micro-test scratch work goes in `MT="${TMPDIR:-/tmp}/tdd-microtest"` — a temp directory OUTSIDE the repo. Export `MT` once per session and use it everywhere the plan says `$MT`. Never commit scratch artifacts.
- Edits are exact-match replacements. If an old-string does not match byte-for-byte, STOP and report.
- Commit messages in English, `docs:` prefix convention.

---

### Task 1: Baseline micro-test (RED) — does the current implementer prompt permit skipping TDD?

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (current version, unmodified)
- Create (scratch, outside repo): `$MT/slugify-brief.md`, one scratch git repo per rep under `$MT/rep1..3`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: baseline verdict (`N of 3 reps skipped test-first`) consumed by Task 2's stop-condition

- [ ] **Step 1: Prepare the scratch task brief**

Run `export MT="${TMPDIR:-/tmp}/tdd-microtest" && mkdir -p "$MT"`, then create `$MT/slugify-brief.md` with exactly this content (note: it asks for tests but deliberately does NOT mention TDD or test-first — that is the tempting condition):

```markdown
# Task 1: slugify utility

Implement `slugify(text: str) -> str` in `slugify.py`:

- lowercase the input
- spaces and underscores become single hyphens
- runs of hyphens collapse to one; strip leading/trailing hyphens
- remove characters that are not alphanumeric or hyphen

Include unit tests in `test_slugify.py` (pytest). Commit when done.
```

- [ ] **Step 2: Run 3 baseline reps**

For each rep i in 1..3: create a fresh scratch repo `mkdir -p "$MT/rep$i" && cd "$MT/rep$i" && git init -q`, then dispatch ONE `general-purpose` subagent whose prompt is the CURRENT `skills/subagent-driven-development/implementer-prompt.md` template filled in as: Task N = "Task 1: slugify utility"; `[BRIEF_FILE]` = `$MT/slugify-brief.md`; Context = "Greenfield micro-project; this is the only task."; `[directory]` = `$MT/rep$i`; `[REPORT_FILE]` = `$MT/rep$i-report.md`; model = a mid-tier model (per SDD Model Selection for a 1-file mechanical task).

- [ ] **Step 3: Judge each rep**

For each rep, inspect `git log --format='%h %s' --reverse` and the report file in the rep's repo. A rep PASSES test-first if there is evidence the test existed and was run failing BEFORE the implementation (RED evidence in the report, or a test-only commit preceding implementation). A rep FAILS if implementation appeared first or no failing run is evidenced. Record verdicts verbatim in `$MT/baseline-verdicts.md`.

- [ ] **Step 4: Apply the stop-condition**

- If **all 3 reps** show test-first behavior: the baseline does not exhibit the failure. Per writing-skills ("If the control doesn't exhibit the failure, there is nothing to fix — stop"), SKIP Tasks 2–3, report this to the human, and continue with Task 4.
- If **at least 1 rep** skips test-first: the loophole is real. Proceed to Task 2.

---

### Task 2: Branch `fix/implementer-tdd-default` — close the loophole (GREEN)

**Files:**
- Modify: `skills/subagent-driven-development/implementer-prompt.md:36,118`

**Interfaces:**
- Consumes: baseline verdict from Task 1 (proceed only if at least 1 rep failed)
- Produces: branch `fix/implementer-tdd-default` with edits; Task 3 verifies and commits

- [ ] **Step 1: Create the branch**

Run: `git switch main && git status --porcelain && git switch -c fix/implementer-tdd-default`
Expected: empty `status` output, then `Switched to a new branch 'fix/implementer-tdd-default'`

- [ ] **Step 2: Make TDD the default in the job list**

In `skills/subagent-driven-development/implementer-prompt.md`, replace exactly:

```markdown
    1. Implement exactly what the task specifies
    2. Write tests (following TDD if task says to)
```

with:

```markdown
    1. Implement exactly what the task specifies
    2. Write tests following superpowers:test-driven-development — mandatory
       unless your task brief explicitly waives TDD
```

- [ ] **Step 3: Make the report's TDD-evidence condition match**

Replace exactly:

```markdown
    - **TDD Evidence** (if TDD was required for this task):
```

with:

```markdown
    - **TDD Evidence** (unless your brief explicitly waived TDD):
```

Rationale: the TDD skill's Iron Law is unconditional ("no exceptions without your human partner's permission") and SDD's Integration section says "Subagents follow TDD for each task" — but the prompt's "if task says to" let implementers skip TDD whenever a brief was silent. The waiver now has to be explicit, which matches the Iron Law's escalation path.

- [ ] **Step 4: Verify the edits**

Run: `grep -n "if task says to\|if TDD was required" skills/subagent-driven-development/implementer-prompt.md || true`
Expected: no output

Run: `grep -n "explicitly waive" skills/subagent-driven-development/implementer-prompt.md`
Expected: 2 matches

---

### Task 3: Re-test (GREEN verification) and commit

**Files:**
- Read: `skills/subagent-driven-development/implementer-prompt.md` (edited version from Task 2)

**Interfaces:**
- Consumes: branch `fix/implementer-tdd-default` with Task 2's edits (stay on it)
- Produces: committed branch + verdict comparison

- [ ] **Step 1: Run 3 reps with the edited prompt**

Repeat Task 1 Steps 2–3 exactly, with two changes: use the EDITED template from this branch, and fresh scratch repos `$MT/rep-after$i`. Record verdicts in `$MT/after-verdicts.md`.

- [ ] **Step 2: Compare**

Expected: 3/3 reps show test-first behavior (RED evidence in report or test-first commit order). If any rep still skips TDD, STOP — report both verdict files to the human with the failing rep's rationalization quoted verbatim; the wording needs another iteration (writing-skills REFACTOR), which is a human decision, not an improvised edit.

- [ ] **Step 3: Commit**

```bash
git add skills/subagent-driven-development/implementer-prompt.md
git commit -m "docs(sdd): make TDD the implementer default; waiver must be explicit in the brief"
```

- [ ] **Step 4: Attach evidence**

Copy `baseline-verdicts.md` and `after-verdicts.md` contents into your task report (not into the repo) — they are the RED/GREEN evidence for the human's review.

---

### Task 4: Branch `fix/vbc-sdd-trust-note` — reconcile SDD with verification-before-completion

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:151` (insert new section after "Handling Implementer Status", before "Handling Reviewer ⚠️ Items")
- Read: `skills/verification-before-completion/SKILL.md` (wording cross-check)

**Interfaces:**
- Consumes: nothing (branch created from `main`)
- Produces: branch `fix/vbc-sdd-trust-note` with one commit

- [ ] **Step 1: Create the branch**

Run: `git switch main && git switch -c fix/vbc-sdd-trust-note`
Expected: `Switched to a new branch 'fix/vbc-sdd-trust-note'`

- [ ] **Step 2: Insert the Verification Contract section**

In `skills/subagent-driven-development/SKILL.md`, replace exactly:

```markdown
**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Handling Reviewer ⚠️ Items
```

with:

```markdown
**Never** ignore an escalation or force the same model to retry without changes. If the implementer said it's stuck, something needs to change.

## Verification Contract

Marking a task complete is a completion claim —
superpowers:verification-before-completion governs it. In this workflow
the required evidence is: the implementer's report file containing the
test commands and their output (TDD evidence), plus the task reviewer's
verdicts on the diff. Do not re-run the implementer's suite to
double-check a clean report — but never mark a task complete without
both pieces of evidence on file. The fresh full-suite verification
happens once, in superpowers:finishing-a-development-branch.

## Handling Reviewer ⚠️ Items
```

- [ ] **Step 3: Wording cross-check against verification-before-completion**

Read `skills/verification-before-completion/SKILL.md` in full. Confirm the new section: (a) does not contradict the Iron Law's wording — it defines what the "verification evidence" IS for a controller (report file + reviewer verdict), rather than exempting the controller from having evidence; (b) does not weaken the "Agent delegation" row (the reviewer's diff reading satisfies "Check VCS diff / Verify changes"). If either check fails, STOP and report the conflicting sentences verbatim to the human — do not rewrite VBC.

- [ ] **Step 4: Verify the edit**

Run: `grep -n "Verification Contract" skills/subagent-driven-development/SKILL.md`
Expected: 1 match, located between "Handling Implementer Status" and "Handling Reviewer ⚠️ Items" (confirm with `grep -n "## Handling\|## Verification" skills/subagent-driven-development/SKILL.md`)

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs(sdd): add Verification Contract reconciling task completion with verification-before-completion"
```

---

### Task 5: Final verification and report

**Files:** none (read-only)

**Interfaces:**
- Consumes: branches from Tasks 2–4 (Task 2/3's branch may be absent if the Task 1 stop-condition fired)
- Produces: summary for the human

- [ ] **Step 1: Verify branch contents**

```bash
git switch main
for b in fix/implementer-tdd-default fix/vbc-sdd-trust-note; do
  echo "=== $b"; git log --oneline main..$b 2>/dev/null || echo "(branch not created — stop-condition fired)"
done
```

Expected: `fix/vbc-sdd-trust-note` has 1 commit; `fix/implementer-tdd-default` has 1 commit OR was skipped with the baseline evidence explaining why.

- [ ] **Step 2: Report**

Report to the human: branch names and commits, the baseline/after micro-test verdicts (or the stop-condition outcome), and that integration is left to superpowers:finishing-a-development-branch after review. Recommend a fuller eval (5+ reps, per writing-skills) before any upstream PR of the implementer-prompt change.
