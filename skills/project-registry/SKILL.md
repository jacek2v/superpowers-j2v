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
