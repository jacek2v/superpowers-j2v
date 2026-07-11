# Skills Consistency — Core Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Remove the dead checkbox-tracking promise, re-sync `requesting-code-review` (and its `code-reviewer.md` template) with the June 2026 SDD redesign, and delete two orphaned reviewer prompt files.

**Architecture:** Documentation-only edits in the `superpowers-j2v.git` skills plugin, grouped into three feature branches created from `main`. Each branch is independently reviewable. Verification is exact-text greps — there is no code to test.

**Tech Stack:** Markdown (Claude Code skill docs), git, grep.

**Requirements:** No CONTEXT.md registry exists for this project — none.

## Global Constraints

- Repo: `<repo>` — an independent git repo. Run ALL commands from this directory.
- Create every branch from `main`. Do NOT merge any branch in this plan — leave them for human review; integration happens per-branch via superpowers:finishing-a-development-branch afterwards.
- Feature branches ARE the isolation for this plan; do not create worktrees.
- Never touch `docs/`, `RELEASE-NOTES.md`, `tests/`, `hooks/` — historical/infra content stays as-is.
- Edits are exact-match replacements. If an old-string does not match the file byte-for-byte, STOP and report — do not improvise a similar edit.
- `grep` exiting 1 on "no match" is SUCCESS for negative checks — append `|| true` so it doesn't surface as an error.
- Commit messages in English, `docs:` / `chore:` prefix convention.

---

### Task 1: Branch `fix/drop-checkbox-tracking` — remove the tracking promise

**Files:**
- Modify: `skills/writing-plans/SKILL.md:69`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: branch `fix/drop-checkbox-tracking` with one commit

- [ ] **Step 1: Create the branch**

Run: `git switch main && git status --porcelain && git switch -c fix/drop-checkbox-tracking`
Expected: empty `status` output (clean tree), then `Switched to a new branch 'fix/drop-checkbox-tracking'`

- [ ] **Step 2: Remove the tracking sentence from the plan header template**

In `skills/writing-plans/SKILL.md`, replace exactly:

```markdown
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.
```

with:

```markdown
> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.
```

Rationale (context for the reviewer): the fork's checkbox-ticking mechanism (commits `be4bc6a`, `cdd1401`) was dropped by the v6.1.1 upstream merge; SDD now tracks progress in its ledger, executing-plans in todos. Nothing ticks checkboxes anymore, so the promise is dead. The `- [ ]` syntax inside the Task Structure template stays — it is plain step formatting.

- [ ] **Step 3: Verify the promise is gone and nothing else mentions it**

Run: `grep -rn "syntax for tracking" skills/ || true`
Expected: no output

Run: `grep -c "For agentic workers" skills/writing-plans/SKILL.md`
Expected: `1` (header line still present, just shortened)

- [ ] **Step 4: Commit**

```bash
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): drop checkbox-tracking promise from plan header"
```

---

### Task 2: Branch `fix/requesting-code-review-sdd-sync` — re-scope SKILL.md to final/ad-hoc reviews

**Files:**
- Modify: `skills/requesting-code-review/SKILL.md:12-17,26-30,50-75,77-91`

**Interfaces:**
- Consumes: nothing (branch created from `main`, independent of Task 1)
- Produces: branch `fix/requesting-code-review-sdd-sync`; Task 3 adds a second commit to this same branch

- [ ] **Step 1: Create the branch**

Run: `git switch main && git switch -c fix/requesting-code-review-sdd-sync`
Expected: `Switched to a new branch 'fix/requesting-code-review-sdd-sync'`

- [ ] **Step 2: Fix the "Mandatory" list**

In `skills/requesting-code-review/SKILL.md`, replace exactly:

```markdown
**Mandatory:**
- After each task in subagent-driven development
- After completing major feature
- Before merge to main
```

with:

```markdown
**Mandatory:**
- Final whole-branch review in subagent-driven development (per-task reviews use that skill's task-reviewer-prompt.md, not this template)
- After completing major feature
- Before merge to main
```

- [ ] **Step 3: Fix the BASE_SHA guidance (ban HEAD~1)**

Replace exactly:

````markdown
**1. Get git SHAs:**
```bash
BASE_SHA=$(git rev-parse HEAD~1)  # or origin/main
HEAD_SHA=$(git rev-parse HEAD)
```
````

with:

````markdown
**1. Get git SHAs:**
```bash
BASE_SHA=$(git merge-base main HEAD)  # or the SHA you recorded before the work began
HEAD_SHA=$(git rev-parse HEAD)
```

Never use `HEAD~1` as the base of a multi-commit range — it silently drops every commit except the last.
````

- [ ] **Step 4: Replace the mid-plan example with a final-review example**

Replace exactly:

```markdown
[Just completed Task 2: Add verification function]

You: Let me request code review before proceeding.

BASE_SHA=$(git log --oneline | grep "Task 1" | head -1 | awk '{print $1}')
HEAD_SHA=$(git rev-parse HEAD)
```

with:

```markdown
[All plan tasks complete; time for the final whole-branch review]

You: Let me request the final code review before finishing.

BASE_SHA=$(git merge-base main HEAD)
HEAD_SHA=$(git rev-parse HEAD)
```

Then, in the same example, replace exactly:

```markdown
  Assessment: Ready to proceed
```

with:

```markdown
  Assessment: Ready to merge with fixes
```

and replace exactly:

```markdown
You: [Fix progress indicators]
[Continue to Task 3]
```

with:

```markdown
You: [Fix progress indicators]
[Proceed to superpowers:finishing-a-development-branch]
```

- [ ] **Step 5: Fix the Integration section**

Replace exactly:

```markdown
**Subagent-Driven Development:**
- Review after EACH task
- Catch issues before they compound
- Fix before moving to next task
```

with:

```markdown
**Subagent-Driven Development:**
- This template runs ONCE, as the final whole-branch review
- Per-task reviews use that skill's task-reviewer-prompt.md
- Fix Critical/Important findings before merge
```

- [ ] **Step 6: Verify**

Run: `grep -n "HEAD~1" skills/requesting-code-review/SKILL.md`
Expected: exactly one match — the "Never use \`HEAD~1\`" warning line

Run: `grep -n "After each task in subagent\|Review after EACH task" skills/requesting-code-review/SKILL.md || true`
Expected: no output

- [ ] **Step 7: Commit**

```bash
git add skills/requesting-code-review/SKILL.md
git commit -m "docs(requesting-code-review): scope template to final/ad-hoc reviews; ban HEAD~1 base"
```

---

### Task 3: Same branch — bring `code-reviewer.md` up to the SDD template contract

**Files:**
- Modify: `skills/requesting-code-review/code-reviewer.md:8-31,128-133`

**Interfaces:**
- Consumes: branch `fix/requesting-code-review-sdd-sync` from Task 2 (stay on it)
- Produces: second commit on the same branch

- [ ] **Step 1: Confirm you are on the branch**

Run: `git branch --show-current`
Expected: `fix/requesting-code-review-sdd-sync`

- [ ] **Step 2: Add the REQUIRED model field**

In `skills/requesting-code-review/code-reviewer.md`, replace exactly:

```markdown
Subagent (general-purpose):
  description: "Review code changes"
  prompt: |
```

with:

```markdown
Subagent (general-purpose):
  description: "Review code changes"
  model: [MODEL — REQUIRED: for a final whole-branch review use the most
         capable available model; an omitted model silently inherits the
         session's model]
  prompt: |
```

- [ ] **Step 3: Add the DIFF_FILE hand-off (mirrors task-reviewer-prompt.md)**

Replace exactly:

````markdown
    ## Git Range to Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```
````

with:

````markdown
    ## Git Range to Review

    **Base:** [BASE_SHA]
    **Head:** [HEAD_SHA]
    **Diff file:** [DIFF_FILE]

    Read the diff file once — it contains the commit list, a stat summary,
    and the full diff with surrounding context. If the diff file is missing,
    fetch the diff yourself:

    ```bash
    git diff --stat [BASE_SHA]..[HEAD_SHA]
    git diff [BASE_SHA]..[HEAD_SHA]
    ```

    ## Deferred Minor Findings

    [MINOR_FINDINGS — Minor items recorded in the progress ledger during
    per-task reviews, if any. Triage them: which must be fixed before
    merge, which can wait.]
````

- [ ] **Step 4: Document the new placeholders**

Replace exactly:

```markdown
**Placeholders:**
- `[DESCRIPTION]` — brief summary of what was built
- `[PLAN_OR_REQUIREMENTS]` — what it should do (plan file path, task text, or requirements)
- `[BASE_SHA]` — starting commit
- `[HEAD_SHA]` — ending commit
```

with:

```markdown
**Placeholders:**
- `[MODEL]` — REQUIRED: reviewer model; a final whole-branch review gets the most capable available model
- `[DESCRIPTION]` — brief summary of what was built
- `[PLAN_OR_REQUIREMENTS]` — what it should do (plan file path, task text, or requirements)
- `[BASE_SHA]` — starting commit
- `[HEAD_SHA]` — ending commit
- `[DIFF_FILE]` — review package path (subagent-driven-development's `scripts/review-package BASE HEAD` prints it); for standalone reviews outside SDD, write "none — use the git commands"
- `[MINOR_FINDINGS]` — deferred Minor findings from per-task reviews; write "none" if there are none
```

- [ ] **Step 5: Verify**

Run: `grep -c "REQUIRED" skills/requesting-code-review/code-reviewer.md`
Expected: `2` or more (model line + placeholder line)

Run: `grep -n "DIFF_FILE\|MINOR_FINDINGS" skills/requesting-code-review/code-reviewer.md | head -8`
Expected: matches in both the prompt body and the Placeholders list

- [ ] **Step 6: Commit**

```bash
git add skills/requesting-code-review/code-reviewer.md
git commit -m "docs(requesting-code-review): add REQUIRED model, DIFF_FILE and MINOR_FINDINGS slots to reviewer template"
```

---

### Task 4: Branch `chore/remove-orphaned-reviewer-prompts` — delete dead templates

**Files:**
- Delete: `skills/brainstorming/spec-document-reviewer-prompt.md`
- Delete: `skills/writing-plans/plan-document-reviewer-prompt.md`

**Interfaces:**
- Consumes: nothing (branch created from `main`)
- Produces: branch `chore/remove-orphaned-reviewer-prompts` with one commit

- [ ] **Step 1: Create the branch**

Run: `git switch main && git switch -c chore/remove-orphaned-reviewer-prompts`
Expected: `Switched to a new branch 'chore/remove-orphaned-reviewer-prompts'`

- [ ] **Step 2: Confirm the files are unreferenced (pre-delete evidence)**

Run: `grep -rn "spec-document-reviewer\|plan-document-reviewer" skills/ hooks/ scripts/ tests/ || true`
Expected: no output (references exist only in `docs/` history and `RELEASE-NOTES.md`, which stay untouched)

- [ ] **Step 3: Delete both files**

```bash
git rm skills/brainstorming/spec-document-reviewer-prompt.md skills/writing-plans/plan-document-reviewer-prompt.md
```

Rationale: the "Replace subagent review loops with lightweight inline self-review" change (March 2026, present in both fork and upstream) made spec/plan self-review inline; these dispatch templates have been dead since.

- [ ] **Step 4: Commit**

```bash
git commit -m "chore: remove orphaned document-reviewer prompt templates (inline self-review since March 2026)"
```

---

### Task 5: Final verification and report

**Files:** none (read-only)

**Interfaces:**
- Consumes: the three branches from Tasks 1–4
- Produces: summary for the human

- [ ] **Step 1: Verify branch contents**

```bash
git switch main
for b in fix/drop-checkbox-tracking fix/requesting-code-review-sdd-sync chore/remove-orphaned-reviewer-prompts; do
  echo "=== $b"; git log --oneline main..$b
done
```

Expected: 1 commit, 2 commits, 1 commit respectively; working tree on `main` clean.

- [ ] **Step 2: Report**

Report to the human: the three branch names, their commits, and that integration (merge/PR per branch) is deliberately left to superpowers:finishing-a-development-branch after review.
