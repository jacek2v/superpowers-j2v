# Skills Consistency — Structural Fixes Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Give `executing-plans` one coherent identity (subagent availability, not "session"), fix stale cross-skill pointers, wire `using-git-worktrees` into both executor flows, and normalize requirement/feature ID notation to `R-XXX` / `F-XXX`.

**Architecture:** Documentation-only edits in the `superpowers-j2v.git` skills plugin, grouped into three feature branches created from `main`. Branches touch overlapping files on mostly disjoint hunks; the SDD example region is edited by two branches on adjacent lines, so merging the second of them may raise a trivial conflict (keep both changes). Verification is exact-text greps.

**Tech Stack:** Markdown (Claude Code skill docs), git, grep, sed.

**Requirements:** No CONTEXT.md registry exists for this project — none.

## Global Constraints

- Repo: `<repo>` — an independent git repo. Run ALL commands from this directory.
- Create every branch from `main`. Do NOT merge any branch in this plan — integration happens per-branch via superpowers:finishing-a-development-branch after human review.
- Feature branches ARE the isolation for this plan; do not create worktrees.
- Never touch `docs/`, `RELEASE-NOTES.md`, `tests/`, `hooks/`.
- Edits are exact-match replacements. If an old-string does not match byte-for-byte, STOP and report — do not improvise.
- `grep` exiting 1 on "no match" is SUCCESS for negative checks — append `|| true`.
- Commit messages in English, `docs:` prefix convention.
- The chosen framing (decided with the human): subagent-driven-development vs executing-plans differ by **subagent availability** — executing-plans is the no-subagents fallback. Wording in edits below follows from this decision; do not re-litigate it.

---

### Task 1: Branch `fix/executing-plans-identity` — one coherent story across three skills

**Files:**
- Modify: `skills/executing-plans/SKILL.md:1-4`
- Modify: `skills/writing-plans/SKILL.md:174-193`
- Modify: `skills/subagent-driven-development/SKILL.md:19-44,343-355,415-429`

**Interfaces:**
- Consumes: nothing (first task)
- Produces: branch `fix/executing-plans-identity` with one commit

- [ ] **Step 1: Create the branch**

Run: `git switch main && git status --porcelain && git switch -c fix/executing-plans-identity`
Expected: empty `status` output, then `Switched to a new branch 'fix/executing-plans-identity'`

- [ ] **Step 2: Fix the executing-plans frontmatter**

In `skills/executing-plans/SKILL.md`, replace exactly:

```markdown
description: Use when you have a written implementation plan to execute in a separate session with review checkpoints
```

with:

```markdown
description: Use when you have a written implementation plan to execute and subagent dispatch is unavailable
```

Rationale: the process has no review checkpoints (Step 2 executes all tasks, report comes at the end), and the skill runs in whatever session invokes it. Its own Note already says "If subagents are available, use superpowers:subagent-driven-development instead" — that is the real dividing line.

- [ ] **Step 3: Fix the writing-plans execution handoff**

In `skills/writing-plans/SKILL.md`, replace exactly:

```markdown
**2. Inline Execution** - Execute tasks in this session using executing-plans, batch execution with checkpoints
```

with:

```markdown
**2. Inline Execution** - I execute tasks directly in this session without subagents, using executing-plans
```

Then replace exactly:

```markdown
**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Batch execution with checkpoints for review
```

with:

```markdown
**If Inline Execution chosen:**
- **REQUIRED SUB-SKILL:** Use superpowers:executing-plans
- Direct task-by-task execution in this session
```

- [ ] **Step 4: Fix the SDD when-to-use graph**

In `skills/subagent-driven-development/SKILL.md`, replace exactly:

```dot
    "Stay in this session?" [shape=diamond];
```

with:

```dot
    "Subagents available?" [shape=diamond];
```

Then replace exactly:

```dot
    "Tasks mostly independent?" -> "Stay in this session?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Stay in this session?" -> "subagent-driven-development" [label="yes"];
    "Stay in this session?" -> "executing-plans" [label="no - parallel session"];
```

with:

```dot
    "Tasks mostly independent?" -> "Subagents available?" [label="yes"];
    "Tasks mostly independent?" -> "Manual execution or brainstorm first" [label="no - tightly coupled"];
    "Subagents available?" -> "subagent-driven-development" [label="yes"];
    "Subagents available?" -> "executing-plans" [label="no"];
```

- [ ] **Step 5: Fix the SDD comparison headings and Integration line**

Replace exactly:

```markdown
**vs. Executing Plans (parallel session):**
```

with:

```markdown
**vs. Executing Plans (no subagents):**
```

Then, in the Advantages section, replace exactly:

```markdown
**vs. Executing Plans:**
- Same session (no handoff)
- Continuous progress (no waiting)
- Review checkpoints automatic
```

with:

```markdown
**vs. Executing Plans:**
- Fresh subagent per task (isolated context)
- Automatic per-task review gates
- Continuous progress (no waiting)
```

Then, in the Integration section, replace exactly:

```markdown
**Alternative workflow:**
- **superpowers:executing-plans** - Use for parallel session instead of same-session execution
```

with:

```markdown
**Alternative workflow:**
- **superpowers:executing-plans** - Use when subagent dispatch is unavailable
```

- [ ] **Step 6: Verify**

Run: `grep -rn "parallel session\|separate session\|checkpoints" skills/executing-plans/SKILL.md skills/writing-plans/SKILL.md skills/subagent-driven-development/SKILL.md || true`
Expected: no output

Run: `grep -c "Subagents available?" skills/subagent-driven-development/SKILL.md`
Expected: `3` (node declaration + two edge lines)

- [ ] **Step 7: Commit**

```bash
git add skills/executing-plans/SKILL.md skills/writing-plans/SKILL.md skills/subagent-driven-development/SKILL.md
git commit -m "docs: reframe SDD vs executing-plans split as subagent availability, not session"
```

---

### Task 2: Branch `fix/cross-skill-pointers` — stale pointer and incomplete example

**Files:**
- Modify: `skills/brainstorming/SKILL.md:36`
- Modify: `skills/subagent-driven-development/SKILL.md:336-340`

**Interfaces:**
- Consumes: nothing (branch created from `main`; hunks are disjoint from Task 1's)
- Produces: branch `fix/cross-skill-pointers`; Task 3 adds a second commit to this same branch

- [ ] **Step 1: Create the branch**

Run: `git switch main && git switch -c fix/cross-skill-pointers`
Expected: `Switched to a new branch 'fix/cross-skill-pointers'`

- [ ] **Step 2: Fix the brainstorming step pointer**

In `skills/brainstorming/SKILL.md`, replace exactly:

```markdown
2. **Project registry check** — if `docs/superpowers/CONTEXT.md` exists, read it for awareness of existing requirements and features (conflict flags presented at step 6; see project-registry skill, operation 3)
```

with:

```markdown
2. **Project registry check** — if `docs/superpowers/CONTEXT.md` exists, read it for awareness of existing requirements and features (conflict flags presented at step 8; see project-registry skill, operation 3)
```

Rationale: the conflict check is checklist step 8 ("Conflict check — … run project-registry skill operation 3 against the approved design"), and project-registry op 3 fires after design approval. "Step 6" is a leftover from pre-renumbering.

- [ ] **Step 3: Complete the SDD example workflow ending**

In `skills/subagent-driven-development/SKILL.md`, replace exactly:

```markdown
[Use superpowers:project-registry (operation 4)]
  - Remove spec from STATE
  - Add FXXX entry to FEATURES

Done!
```

with:

```markdown
[Use superpowers:project-registry (operation 4)]
  - Remove spec from STATE
  - Add FXXX entry to FEATURES

[Use superpowers:finishing-a-development-branch]

Done!
```

Rationale: the process graph ends at finishing-a-development-branch (the green terminal node); the example skipped it. Keep `FXXX` spelled as-is here — notation is normalized separately in the `docs/normalize-rxxx-notation` branch.

- [ ] **Step 4: Verify**

Run: `grep -n "presented at step 8" skills/brainstorming/SKILL.md`
Expected: 1 match

Run: `grep -n "presented at step 6" skills/brainstorming/SKILL.md || true`
Expected: no output

Run: `grep -B1 -A2 "finishing-a-development-branch\]" skills/subagent-driven-development/SKILL.md | head -6`
Expected: shows the new example line above `Done!`

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/subagent-driven-development/SKILL.md
git commit -m "docs: fix stale brainstorming step pointer; add finishing step to SDD example"
```

---

### Task 3: Same branch — wire using-git-worktrees into both executor flows

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md:87-89`
- Modify: `skills/executing-plans/SKILL.md:18-23`

**Interfaces:**
- Consumes: branch `fix/cross-skill-pointers` from Task 2 (stay on it)
- Produces: second commit on the same branch

- [ ] **Step 1: Confirm you are on the branch**

Run: `git branch --show-current`
Expected: `fix/cross-skill-pointers`

- [ ] **Step 2: Wire the worktree step into SDD pre-flight**

In `skills/subagent-driven-development/SKILL.md`, replace exactly:

```markdown
## Pre-Flight Plan Review

Before dispatching Task 1, scan the plan once for conflicts:
```

with:

```markdown
## Pre-Flight Plan Review

Before dispatching Task 1, ensure an isolated workspace exists (**REQUIRED SUB-SKILL:** superpowers:using-git-worktrees), then scan the plan once for conflicts:
```

- [ ] **Step 3: Wire the worktree step into executing-plans Step 1**

In `skills/executing-plans/SKILL.md`, replace exactly:

```markdown
### Step 1: Load and Review Plan
1. Read plan file
2. Review critically - identify any questions or concerns about the plan
3. If concerns: Raise them with your human partner before starting
4. If no concerns: Create todos for the plan items and proceed
```

with:

```markdown
### Step 1: Load and Review Plan
1. Ensure an isolated workspace exists — **REQUIRED SUB-SKILL:** superpowers:using-git-worktrees
2. Read plan file
3. Review critically - identify any questions or concerns about the plan
4. If concerns: Raise them with your human partner before starting
5. If no concerns: Create todos for the plan items and proceed
```

Rationale: both skills list using-git-worktrees under "Required workflow skills" but neither process ever invokes it — the "Never start implementation on main/master without explicit user consent" red flag had no supporting step.

- [ ] **Step 4: Verify**

Run: `grep -n "using-git-worktrees" skills/subagent-driven-development/SKILL.md skills/executing-plans/SKILL.md`
Expected: each file matches at least twice — once in the process flow (new), once in the Integration/Required list (existing)

- [ ] **Step 5: Commit**

```bash
git add skills/subagent-driven-development/SKILL.md skills/executing-plans/SKILL.md
git commit -m "docs: wire using-git-worktrees into SDD pre-flight and executing-plans step 1"
```

---

### Task 4: Branch `docs/normalize-rxxx-notation` — align ID notation with project-registry

**Files:**
- Modify: `skills/brainstorming/SKILL.md` (3 lines)
- Modify: `skills/writing-plans/SKILL.md` (4 lines)
- Modify: `skills/executing-plans/SKILL.md` (1 line)
- Modify: `skills/subagent-driven-development/SKILL.md` (1 line)

**Interfaces:**
- Consumes: nothing (branch created from `main`)
- Produces: branch `docs/normalize-rxxx-notation` with one commit. NOTE: this branch and `fix/cross-skill-pointers` both edit the SDD example ending on adjacent lines — whichever merges second may raise a trivial conflict; resolve by keeping both changes (`Add F-XXX entry` line AND the `[Use superpowers:finishing-a-development-branch]` line)

- [ ] **Step 1: Create the branch**

Run: `git switch main && git switch -c docs/normalize-rxxx-notation`
Expected: `Switched to a new branch 'docs/normalize-rxxx-notation'`

- [ ] **Step 2: Record the pre-change state**

Run: `grep -rn "RXXX\|FXXX" skills/ | grep -v "R-XXX" | grep -v "F-XXX"`
Expected: 9 lines total — brainstorming (3), writing-plans (4), executing-plans (1), subagent-driven-development (1)

- [ ] **Step 3: Normalize the notation**

```bash
sed -i 's/\bRXXX\b/R-XXX/g; s/\bFXXX\b/F-XXX/g' \
  skills/brainstorming/SKILL.md \
  skills/writing-plans/SKILL.md \
  skills/executing-plans/SKILL.md \
  skills/subagent-driven-development/SKILL.md
```

Rationale: project-registry (the owner of the ID scheme) and its `references/project-template.md` write `R-XXX` / `F-XXX` throughout; the four consumer skills drifted to `RXXX` / `FXXX`.

- [ ] **Step 4: Verify**

Run: `grep -rn "RXXX\|FXXX" skills/ | grep -v "R-XXX" | grep -v "F-XXX" || true`
Expected: no output

Run: `git diff --stat`
Expected: exactly the four files listed above, ~9 insertions/deletions

- [ ] **Step 5: Commit**

```bash
git add skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md
git commit -m "docs: normalize requirement/feature ID notation to R-XXX / F-XXX"
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
for b in fix/executing-plans-identity fix/cross-skill-pointers docs/normalize-rxxx-notation; do
  echo "=== $b"; git log --oneline main..$b
done
```

Expected: 1 commit, 2 commits, 1 commit respectively; working tree on `main` clean.

- [ ] **Step 2: Report**

Report to the human: the three branch names, their commits, the warning that `fix/cross-skill-pointers` and `docs/normalize-rxxx-notation` edit adjacent lines in the SDD example (whichever merges second may raise a trivial conflict — keep both changes), and that integration is left to superpowers:finishing-a-development-branch after review.
