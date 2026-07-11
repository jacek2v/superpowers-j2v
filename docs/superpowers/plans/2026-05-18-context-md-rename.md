# CONTEXT.md Rename Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename `PROJECT.md` → `CONTEXT.md` across 7 files in 5 skills of `superpowers-j2v.git`, restructure `project-template.md`, delete `readme-template.md`, and propagate semantic changes (drop SPECIFICATIONS section, derive R-XXX status from STATE/FEATURES, remove Operation 6).

**Architecture:** Two edit categories. (a) **Full rewrites** for `project-registry/SKILL.md` and `project-registry/references/project-template.md` — structure changes. (b) **Surgical edits** (mostly `replace_all` rename + small SPECIFICATIONS-phrase removals) for four consumer skills (`brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`). Plus one file deletion (`references/readme-template.md`). Each task commits independently inside the `superpowers-j2v.git` repo for reviewability.

**Tech Stack:** Markdown files only. Verification via `grep`. Source spec lives in the sibling `docs` repo, not in `superpowers-j2v.git`.

**Requirements:** No `docs/superpowers/PROJECT.md` (or `CONTEXT.md`) exists for `superpowers-j2v.git` itself, so no R-XXX traceability applies. Constraining decisions for this plan come from the spec §2 (D1–D7): `2026-05-18-context-md-rename-design.md`. The engineer should re-read §3 of that spec before executing — it contains the exact prose changes per file.

**Target repo:** `<repo>/` (independent git repo; commits do not affect the parent `docs/` repo).

---

## File Map

| File (paths relative to `superpowers-j2v.git/`) | Action |
|---|---|
| `skills/project-registry/references/project-template.md` | full rewrite |
| `skills/project-registry/references/readme-template.md` | delete |
| `skills/project-registry/SKILL.md` | full rewrite |
| `skills/brainstorming/SKILL.md` | surgical: rename + SPECIFICATIONS phrase removals + flowchart node labels |
| `skills/writing-plans/SKILL.md` | surgical: rename + drop SPECIFICATIONS phrase on context-loading line |
| `skills/executing-plans/SKILL.md` | surgical: rename + remove 2 lines (status mark + SPECIFICATIONS update) |
| `skills/subagent-driven-development/SKILL.md` | surgical: rename only |

Tasks 1–3 are foundation (template, file deletion, skill rewrite). Tasks 4–7 propagate the rename to consumers. Task 8 is global validation.

---

## Task 1: Rewrite `project-template.md`

**Files:**
- Modify: `skills/project-registry/references/project-template.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT" skills/project-registry/references/project-template.md
head -3 skills/project-registry/references/project-template.md
```

Expected: count > 0; header reads `# PROJECT.md Template`.

- [ ] **Step 2: Replace file content**

Use the `Write` tool on `skills/project-registry/references/project-template.md` with this exact content:

`````markdown
# CONTEXT.md Template

Use this template when creating CONTEXT.md for the first time.

```markdown
# CONTEXT: [Project Name]

> AI workspace metadata. Project facts (overview, architecture, tech stack,
> decisions, features) live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Project purpose, architecture, tech stack, repo map, key decisions, domain glossary | `../../<source-repo>/README.md` |
| Backlog, ideas, changelog (if used) | `../../<source-repo>/STATUS.md` |
| Operations procedures (if used) | `../../<source-repo>/OPERATIONS.md` |

When source repo content changes, STATE/REQUIREMENTS sections here update.
Never the reverse — source repo is the source of truth.

## STATE

Specs in development:

- [Spec title](specs/YYYY-MM-DD-feature-design.md)

## REQUIREMENTS

Grouped by originating spec. Each R-XXX: 1–3 sentences + link to spec.
Status derived from STATE (in-progress) and FEATURES (implemented).
Explicit `[deprecated YYYY-MM-DD, superseded by R-NNN]` when retired.

### R-001 .. R-00N (YYYY-MM-DD) — <feature name>
*Spec: [`YYYY-MM-DD-feature-design.md`](specs/YYYY-MM-DD-feature-design.md)*

- **R-001** <constraining decision, 1–3 sentences>
- **R-002** <constraining decision, 1–3 sentences>

## FEATURES

Index only — feature details live in source repo README/changelog.

| ID    | Description           | Requirements   | Spec                          |
|-------|-----------------------|----------------|-------------------------------|
```
`````

- [ ] **Step 3: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT" skills/project-registry/references/project-template.md
grep -c "CONTEXT.md Template\|## Source of truth" skills/project-registry/references/project-template.md
```

Expected: `0` for first; ≥`2` for second.

- [ ] **Step 4: Commit**

```bash
cd <repo>
git add skills/project-registry/references/project-template.md
git commit -m "docs(project-registry): rewrite project-template.md as CONTEXT.md template

Drops SPECIFICATIONS, adds Source of truth pointer block, restructures
REQUIREMENTS as flat list grouped by spec, FEATURES as index table with
R-XXX cross-reference and spec link."
```

---

## Task 2: Delete `readme-template.md`

**Files:**
- Delete: `skills/project-registry/references/readme-template.md`

- [ ] **Step 1: Verify file exists**

```bash
ls <repo>/skills/project-registry/references/readme-template.md
```

Expected: file path printed (no `No such file` error).

- [ ] **Step 2: Delete with git rm**

```bash
cd <repo>
git rm skills/project-registry/references/readme-template.md
```

Expected: `rm 'skills/project-registry/references/readme-template.md'`.

- [ ] **Step 3: Verify**

```bash
ls <repo>/skills/project-registry/references/
```

Expected: only `project-template.md` listed.

- [ ] **Step 4: Commit**

```bash
cd <repo>
git commit -m "docs(project-registry): remove readme-template.md

Op 6 (Generate/Update README.md) is removed — source repo README is now
the source of truth for project facts, no longer generated from CONTEXT.md."
```

---

## Task 3: Rewrite `project-registry/SKILL.md`

**Files:**
- Modify: `skills/project-registry/SKILL.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/project-registry/SKILL.md
grep -c "### 6\. Generate" skills/project-registry/SKILL.md
```

Expected: both > 0.

- [ ] **Step 2: Replace file content**

Use the `Write` tool on `skills/project-registry/SKILL.md` with this exact content:

`````markdown
---
name: project-registry
description: "Manage CONTEXT.md — the AI workspace registry of in-progress specs, R-XXX constraints, and F-XXX feature index. Project facts (architecture, tech stack, decisions) live in the source repo, not here. Invoked by other skills: brainstorming (conflict check + register spec), subagent-driven-development and executing-plans (register completed feature). Not user-invocable directly."
---

# Project Registry

Manage `docs/superpowers/CONTEXT.md` as a living registry of specs in flight, constraining requirements (R-XXX), and shipped features (F-XXX). This file prevents new work from silently contradicting existing constraints.

Project facts — overview, architecture, tech stack, key strategic decisions, source structure, development setup — live in the source repo (`README.md` and optionally `STATUS.md` / `OPERATIONS.md`). CONTEXT.md links to them via a top-level `## Source of truth` block; it does not duplicate them.

## CONTEXT.md Structure

A pointer block plus three content sections:

- **Source of truth** — table of links to source repo files (README, optionally STATUS / OPERATIONS).
- **STATE** — specs currently in development, with links. Entries appear after brainstorming, disappear when feature ships.
- **REQUIREMENTS** — numbered R-XXX, grouped by originating spec, 1–3 sentences each + spec link. Status is derived from STATE (in-progress) and FEATURES (implemented); only `[deprecated]` is stored inline.
- **FEATURES** — numbered F-XXX. Index table with description, R-XXX cross-reference, and spec link. Added when implementation ships.

For the initial template, read `references/project-template.md`.

## Operations

### 1. Create CONTEXT.md

**When:** First brainstorming session (no CONTEXT.md exists yet).

- Read the approved spec.
- Render from `references/project-template.md`.
- Populate `## Source of truth` with the source repo's `README.md` path. Include rows for `STATUS.md` and `OPERATIONS.md` only if those files exist in the source repo at creation time.
- Add the spec link to STATE.
- Extract constraining decisions from the spec → assign R-001, R-002, ... with 1–3 sentence summaries each. Group them under a single `### R-001 .. R-00N (YYYY-MM-DD) — <feature name>` heading, linked to the spec. Include: architecture choices, explicit constraints, NFRs, trade-offs. Exclude: data model shape, component structure, UI details, framework conventions — these live in the spec and code.
- FEATURES section empty.
- Commit: `docs: create CONTEXT.md with initial spec registry`.

### 2. Update for New Spec

**When:** Brainstorming ends, CONTEXT.md already exists.

- Read current CONTEXT.md and the new approved spec.
- STATE: append new spec link.
- REQUIREMENTS: append a new `### R-NNN .. R-MMM (YYYY-MM-DD) — <feature name>` group with the spec link. Assign next available R-XXX IDs with 1–3 sentence summaries (same filtering as Op 1).
- Commit: `docs: update CONTEXT.md with <feature-name> spec`.

### 3. Conflict Check

**When:** Brainstorming design approved by user, before writing spec, CONTEXT.md exists.

Read CONTEXT.md. Build derived status:

- **implemented R-XXX** — listed in the Requirements column of any F-XXX row in FEATURES.
- **in-progress R-XXX** — its originating spec heading appears in STATE.
- **deprecated R-XXX** — carries an inline `[deprecated …]` marker.

Check the approved design against derived status:

```
For each implemented R-XXX:
  → Does the proposed design MODIFY behavior described by this requirement?
  → If yes: flag to user with the R-XXX ID and the F-XXX that satisfies it.

For each in-progress R-XXX:
  → Does the proposed design CONTRADICT this requirement?
  → If yes: flag to user with the R-XXX ID.

Check STATE:
  → Is there in-progress work touching the same area?
  → If yes: flag potential overlap.
```

Present ALL flags before proceeding. Format:

```
⚠ Conflict check against CONTEXT.md:
- R-002 "localStorage persistence, no backend" (implemented in F-001) —
  proposed change introduces a backend API.
- R-007 "User can archive tasks" (in-progress) —
  proposed change removes task archiving.

These require explicit acknowledgment before proceeding.
```

User decides for each flag:
- **Acknowledge and deprecate** old R-XXX → add inline `[deprecated YYYY-MM-DD, superseded by R-NNN]` marker on the entry.
- **Redesign** to avoid the conflict.
- **Override** with explicit justification.

If no conflicts found, proceed normally — no message needed.

### 4. Register Feature

**When:** Implementation complete, all tasks done and reviewed, BEFORE invoking finishing-a-development-branch.

- Remove the spec entry from STATE.
- Append an F-XXX row to FEATURES with: date, 1-line description, comma-separated R-XXX it satisfies, spec link.
- Commit: `docs: register F-XXX <feature-name> in CONTEXT.md`.

Status of the satisfied R-XXX is now implicitly `implemented` (derived from the FEATURES cross-reference) — no inline status change needed.

### 5. Cleanup Abandoned Spec

**When:** User decides to abandon in-progress work.

- Remove spec entry from STATE.
- Mark relevant R-XXX entries with `~~<text>~~ [deprecated YYYY-MM-DD, abandoned]`.
- Commit: `docs: remove abandoned <feature-name> from CONTEXT.md`.

## ID Assignment

- **R-XXX**: sequential from R-001. Scan all `### R-N .. R-M …` group headings in REQUIREMENTS for the highest ID, increment.
- **F-XXX**: sequential from F-001. Scan FEATURES table for the highest ID, increment.
- Never reuse IDs — deprecated entries keep their numbers.

## Key Principles

- STATE is transient — presence means "in progress", absence means "done or abandoned".
- Not every spec detail is a requirement. "Use localStorage, no backend" constrains future work (requirement). "Tasks displayed in a list" describes what code does (spec detail). Apply the litmus test: would contradicting this need flagging?
- Conflict check is advisory, not blocking — user always decides.
- R-XXX status is derived from STATE (in-progress) and FEATURES (implemented). Only `[deprecated]` is stored inline.
- This skill manages `CONTEXT.md` only. It does not generate, update, or touch source repo files (README, STATUS, OPERATIONS).
`````

- [ ] **Step 3: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/project-registry/SKILL.md
grep -c "### 6\.\|Generate/Update README\|readme-template" skills/project-registry/SKILL.md
grep -c "## CONTEXT.md Structure\|## Source of truth\|### 1\. Create CONTEXT.md\|### 5\. Cleanup" skills/project-registry/SKILL.md
```

Expected: `0` for first two, `≥4` for third.

- [ ] **Step 4: Commit**

```bash
cd <repo>
git add skills/project-registry/SKILL.md
git commit -m "docs(project-registry): rewrite SKILL.md for CONTEXT.md model

- Rename PROJECT.md → CONTEXT.md throughout.
- Drop Operation 6 (Generate/Update README.md).
- Restructure ops 1-5 around new template: R-XXX status derived from
  STATE/FEATURES (no inline column), Source of truth pointer block
  replaces SPECIFICATIONS section."
```

---

## Task 4: Update `brainstorming/SKILL.md`

**Files:**
- Modify: `skills/brainstorming/SKILL.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/brainstorming/SKILL.md
grep -cE "SPECIFICATIONS prose|SPECIFICATIONS \+ STATE" skills/brainstorming/SKILL.md
```

Expected: `15` for first (lines containing `PROJECT.md` — one of them carries two occurrences, total 16 substitutions); `≥2` for second (step 12 body + flowchart node labels + "Update PROJECT.md" body section paragraph).

- [ ] **Step 2: Replace all `PROJECT.md` → `CONTEXT.md`**

Use the `Edit` tool with `replace_all=true`:
- `file_path`: `<repo>/skills/brainstorming/SKILL.md`
- `old_string`: `PROJECT.md`
- `new_string`: `CONTEXT.md`

Expected: 16 replacements.

- [ ] **Step 3: Rewrite step 12 to drop "update SPECIFICATIONS prose,"**

Use the `Edit` tool (single occurrence — unique surrounding context):
- `file_path`: `<repo>/skills/brainstorming/SKILL.md`
- `old_string`: `12. **Update CONTEXT.md** — create or update using project-registry skill (operations 1 or 2): update SPECIFICATIONS prose, add spec to STATE, register new RXXX requirements. Commit.`
- `new_string`: `12. **Update CONTEXT.md** — create or update using project-registry skill (operations 1 or 2): add spec to STATE, register new RXXX requirements. Commit.`

- [ ] **Step 4: Drop SPECIFICATIONS from flowchart node parentheticals**

Use the `Edit` tool with `replace_all=true`:
- `file_path`: `<repo>/skills/brainstorming/SKILL.md`
- `old_string`: `(SPECIFICATIONS + STATE + REQUIREMENTS)`
- `new_string`: `(STATE + REQUIREMENTS)`

Expected: 3 replacements (lines that originally were 67, 91, 92).

- [ ] **Step 5: Fix the "Update CONTEXT.md" body section paragraph**

Use the `Edit` tool:
- `file_path`: `<repo>/skills/brainstorming/SKILL.md`
- `old_string`: `This registers the new spec in STATE, updates SPECIFICATIONS prose, and adds RXXX requirements`
- `new_string`: `This registers the new spec in STATE and adds RXXX requirements`

- [ ] **Step 6: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/brainstorming/SKILL.md
grep -c "SPECIFICATIONS" skills/brainstorming/SKILL.md
grep -c "CONTEXT.md" skills/brainstorming/SKILL.md
```

Expected: `0`, `0`, `15`.

- [ ] **Step 7: Commit**

```bash
cd <repo>
git add skills/brainstorming/SKILL.md
git commit -m "docs(brainstorming): rename PROJECT.md → CONTEXT.md, drop SPECIFICATIONS

Propagates project-registry rename. Step 12 no longer instructs to
'update SPECIFICATIONS prose' — that section is removed from the new
CONTEXT.md template. Flowchart node labels updated (3 occurrences of
'(SPECIFICATIONS + STATE + REQUIREMENTS)' → '(STATE + REQUIREMENTS)')."
```

---

## Task 5: Update `writing-plans/SKILL.md`

**Files:**
- Modify: `skills/writing-plans/SKILL.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/writing-plans/SKILL.md
grep -c "SPECIFICATIONS (current architecture)" skills/writing-plans/SKILL.md
```

Expected: `4` for first (lines — one of them carries two occurrences, total 5 substitutions); `1` for second.

- [ ] **Step 2: Replace all `PROJECT.md` → `CONTEXT.md`**

Use the `Edit` tool with `replace_all=true`:
- `file_path`: `<repo>/skills/writing-plans/SKILL.md`
- `old_string`: `PROJECT.md`
- `new_string`: `CONTEXT.md`

Expected: 5 replacements.

- [ ] **Step 3: Drop SPECIFICATIONS phrase from context-loading line**

Use the `Edit` tool:
- `file_path`: `<repo>/skills/writing-plans/SKILL.md`
- `old_string`: `2. \`docs/superpowers/CONTEXT.md\` if it exists — for SPECIFICATIONS (current architecture) and REQUIREMENTS (RXXX constraints)`
- `new_string`: `2. \`docs/superpowers/CONTEXT.md\` if it exists — for REQUIREMENTS (RXXX constraints)`

- [ ] **Step 4: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/writing-plans/SKILL.md
grep -c "SPECIFICATIONS" skills/writing-plans/SKILL.md
grep -c "CONTEXT.md" skills/writing-plans/SKILL.md
```

Expected: `0`, `0`, `4`.

- [ ] **Step 5: Commit**

```bash
cd <repo>
git add skills/writing-plans/SKILL.md
git commit -m "docs(writing-plans): rename PROJECT.md → CONTEXT.md, drop SPECIFICATIONS

Context-loading step now references REQUIREMENTS only; SPECIFICATIONS
section no longer exists in the CONTEXT.md template."
```

---

## Task 6: Update `executing-plans/SKILL.md`

**Files:**
- Modify: `skills/executing-plans/SKILL.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/executing-plans/SKILL.md
grep -nE "Mark those RXXX as|Update SPECIFICATIONS" skills/executing-plans/SKILL.md
```

Expected: `3` for first; two matched lines (one for "Mark those RXXX as `implemented`", one for "Update SPECIFICATIONS if implementation diverged from design").

- [ ] **Step 2: Replace all `PROJECT.md` → `CONTEXT.md`**

Use the `Edit` tool with `replace_all=true`:
- `file_path`: `<repo>/skills/executing-plans/SKILL.md`
- `old_string`: `PROJECT.md`
- `new_string`: `CONTEXT.md`

Expected: 3 replacements.

- [ ] **Step 3: Remove the "Mark those RXXX as `implemented`" bullet**

Use the `Edit` tool:
- `file_path`: `<repo>/skills/executing-plans/SKILL.md`
- `old_string`: `- Mark those RXXX as \`implemented\`
`
- `new_string`: ``

Note: the trailing newline in `old_string` is intentional — it deletes the entire line including its newline.

- [ ] **Step 4: Remove the "Update SPECIFICATIONS if implementation diverged" bullet**

Use the `Edit` tool:
- `file_path`: `<repo>/skills/executing-plans/SKILL.md`
- `old_string`: `- Update SPECIFICATIONS if implementation diverged from design
`
- `new_string`: ``

- [ ] **Step 5: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/executing-plans/SKILL.md
grep -c "SPECIFICATIONS\|Mark those RXXX" skills/executing-plans/SKILL.md
grep -c "CONTEXT.md" skills/executing-plans/SKILL.md
```

Expected: `0`, `0`, `3`.

Also visually scan the "Step 3: Register Feature" block — it should now contain three bullets (`Remove spec entry`, `Add FXXX entry`, `Commit CONTEXT.md changes`) instead of five.

- [ ] **Step 6: Commit**

```bash
cd <repo>
git add skills/executing-plans/SKILL.md
git commit -m "docs(executing-plans): rename PROJECT.md → CONTEXT.md, drop status/SPECIFICATIONS lines

R-XXX status is now derived from STATE/FEATURES — no inline marking
needed. SPECIFICATIONS section no longer exists. Register Feature step
collapses from 5 bullets to 3."
```

---

## Task 7: Update `subagent-driven-development/SKILL.md`

**Files:**
- Modify: `skills/subagent-driven-development/SKILL.md`

- [ ] **Step 1: Verify current state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/subagent-driven-development/SKILL.md
```

Expected: `1`.

- [ ] **Step 2: Replace `PROJECT.md` → `CONTEXT.md`**

Use the `Edit` tool with `replace_all=true`:
- `file_path`: `<repo>/skills/subagent-driven-development/SKILL.md`
- `old_string`: `PROJECT.md`
- `new_string`: `CONTEXT.md`

Expected: 1 replacement.

- [ ] **Step 3: Verify post-state**

```bash
cd <repo>
grep -c "PROJECT.md" skills/subagent-driven-development/SKILL.md
grep -c "CONTEXT.md" skills/subagent-driven-development/SKILL.md
```

Expected: `0`, `1`.

- [ ] **Step 4: Commit**

```bash
cd <repo>
git add skills/subagent-driven-development/SKILL.md
git commit -m "docs(subagent-driven-development): rename PROJECT.md → CONTEXT.md"
```

---

## Task 8: Cross-skill validation

This task contains no edits — only verification that all prior tasks landed as intended.

- [ ] **Step 1: No `PROJECT.md` references remain anywhere in `skills/`**

```bash
cd <repo>
grep -rln "PROJECT.md" skills/
```

Expected: no output (zero matching files). Any output is a regression — re-examine the failing file and re-run the relevant task.

- [ ] **Step 2: No stale `SPECIFICATIONS` references in affected skills**

```bash
cd <repo>
grep -nE "SPECIFICATIONS" skills/project-registry/ skills/brainstorming/SKILL.md skills/writing-plans/SKILL.md skills/executing-plans/SKILL.md skills/subagent-driven-development/SKILL.md
```

Expected: no output. If matches remain, they were missed — open the file and remove the stray phrase.

(Note: `grep` is scoped to the five skill paths we edited. Other skills in the fork may legitimately use the word `SPECIFICATIONS` in unrelated contexts — those are out of scope.)

- [ ] **Step 3: `readme-template.md` is gone**

```bash
ls <repo>/skills/project-registry/references/
```

Expected: only `project-template.md` listed.

- [ ] **Step 4: New `project-template.md` and `SKILL.md` have the new structure**

```bash
cd <repo>
grep -c "## Source of truth\|# CONTEXT" skills/project-registry/references/project-template.md
grep -cE "^### [12345]\." skills/project-registry/SKILL.md
grep -cE "^### 6\." skills/project-registry/SKILL.md
```

Expected: `≥2` for first (Source of truth heading + CONTEXT title); `5` for second (operations 1-5); `0` for third (Op 6 removed).

- [ ] **Step 5: Brainstorming flowchart no longer mentions SPECIFICATIONS**

```bash
cd <repo>
grep -c "(STATE + REQUIREMENTS)" skills/brainstorming/SKILL.md
grep -c "(SPECIFICATIONS" skills/brainstorming/SKILL.md
```

Expected: `≥3` for first (three flowchart node labels updated); `0` for second.

- [ ] **Step 6: Confirm a clean working tree and review commit log**

```bash
cd <repo>
git status
git log --oneline -10
```

Expected: clean working tree; last 7 commits are the per-task commits in order (`docs(project-registry): rewrite project-template.md ...` through `docs(subagent-driven-development): rename ...`).

- [ ] **Step 7: Invoke project-registry skill (Op 4 equivalent) — out of scope here**

This plan does not invoke project-registry to register itself as F-XXX in any CONTEXT.md, because `superpowers-j2v.git` has no CONTEXT.md (see spec §4 and §6). The user may later choose to create one and register this work retroactively.

---

## Self-Review Notes (writing-plans skill)

1. **Spec coverage:** every decision D1–D7 in the spec maps to one or more tasks: D1 (hardcoded rename) → tasks 1–7 collectively; D2 (drop SPECIFICATIONS) → task 1 (template), task 3 (SKILL.md), task 4–6 (consumer skills); D3 (REQUIREMENTS reformat) → task 1; D4 (status derived) → task 1, task 3 (Op 3, Op 4); D5 (FEATURES index) → task 1; D6 (remove Op 6) → task 2 (delete readme-template), task 3 (new SKILL.md has no Op 6); D7 (full scope) → tasks 4–7.
2. **Placeholder scan:** no `TBD`/`TODO`. Every step has either an exact command, an exact edit specification, or full file content.
3. **Type consistency:** R-XXX format is consistent across template, SKILL.md, and consumer skills. F-XXX format is consistent.
4. **External knowledge:** uses only `git`, `grep`, `ls`, `head`, and the harness's `Edit` / `Write` tools. No external library/API/framework version assumptions.
5. **Requirement traceability:** no R-XXX exist for `superpowers-j2v.git` to trace — `Requirements` field in the header reads "no traceability". Spec decisions D1–D7 traced in (1) above.
