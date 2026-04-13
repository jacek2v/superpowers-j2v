---
name: project-registry
description: "Manage PROJECT.md — the project's single source of truth for architecture, requirements, and features. Also generates/updates README.md in the source code repo. Invoked by other skills: brainstorming (conflict check + register spec), subagent-driven-development and executing-plans (register completed feature, update README). Not user-invocable directly."
---

# Project Registry

Manage `docs/superpowers/PROJECT.md` as a living registry of what the project IS, what decisions constrain it, and what has been built. This file prevents new work from silently contradicting or breaking existing features.

## PROJECT.md Structure

Four sections, in order:

1. **SPECIFICATIONS** — living system overview reflecting current actual architecture (overview, tech stack, source structure, architecture). Use bullet points, tables, and mermaid diagrams. Minimal prose — only what's necessary for clarity. Rewritten to synthesize the full system each time, including implementation divergences. Spec files in `docs/superpowers/specs/` are point-in-time design records — SPECIFICATIONS tracks reality.
2. **STATE** — specs currently in development, with links. Entries appear after brainstorming, disappear when feature ships.
3. **REQUIREMENTS** — numbered RXXX. Developer decisions that constrain future work. Litmus test: "If a future feature contradicted this, would it need flagging?" Yes → requirement. No → implementation detail (lives in spec/code, not here).
4. **FEATURES** — numbered FXXX. Added when implementation ships. Cross-references which RXXX it satisfies.

For the initial template, read `references/project-template.md`.

## Operations

### 1. Create PROJECT.md

**When:** First brainstorming session (no PROJECT.md exists yet).

- Read the approved spec
- Populate SPECIFICATIONS from spec: overview, tech stack, source structure, architecture
- Add spec link to STATE
- Extract constraining decisions from spec → assign R001, R002, ... with status `active`, each with rationale. Include: architecture choices, explicit constraints, NFRs, trade-offs. Exclude: data model shape, component structure, UI details, framework conventions — these live in the spec and code.
- FEATURES section empty
- Commit: `"docs: create PROJECT.md with initial spec registry"`
- Run Operation 6 to generate initial README.md in the source code repo

### 2. Update for New Spec

**When:** Brainstorming ends, PROJECT.md already exists.

- Read current PROJECT.md and the new approved spec
- SPECIFICATIONS: rewrite the section to incorporate new design. Do NOT append — synthesize into one coherent spec reflecting the full system.
- STATE: add new spec link
- REQUIREMENTS: extract constraining decisions (same filtering as operation 1), assign next available RXXX IDs with rationale, status `active`
- Commit: `"docs: update PROJECT.md with <feature-name> spec"`

### 3. Conflict Check

**When:** Brainstorming design approved by user, before writing spec, PROJECT.md exists.

Read PROJECT.md. Check the approved design against existing requirements and features:

```
For each RXXX with status "implemented":
  → Does the proposed design MODIFY behavior described by this requirement?
  → If yes: flag to user with specific ID and feature

For each RXXX with status "active":
  → Does the proposed design CONTRADICT this requirement?
  → If yes: flag to user with specific ID

Check STATE:
  → Is there in-progress work touching the same area?
  → If yes: flag potential overlap
```

Present ALL flags before proceeding. Format:

```
⚠ Conflict check against PROJECT.md:
- R002 "localStorage persistence, no backend" (implemented in F001) —
  proposed change introduces a backend API
- R007 "User can archive tasks" (active, in development) —
  proposed change removes task archiving

These require explicit acknowledgment before proceeding.
```

User decides for each flag:
- **Acknowledge and deprecate** old RXXX → mark `deprecated`
- **Redesign** to avoid the conflict
- **Override** with explicit justification

If no conflicts found, proceed normally — no message needed.

### 4. Register Feature

**When:** Implementation complete, all tasks done and reviewed, BEFORE invoking finishing-a-development-branch.

- Remove the spec entry from STATE
- Add FXXX entry to FEATURES with: date, list of RXXX it satisfies
- Mark those RXXX as `implemented`, fill in Features column
- If implementation diverged from design: update SPECIFICATIONS to reflect actual architecture
- Commit: `"docs: register F00X <feature-name> in PROJECT.md"`
- Run Operation 6 to update README.md with the new feature and any spec/setup changes

### 5. Cleanup Abandoned Spec

**When:** User decides to abandon in-progress work.

- Remove spec entry from STATE
- Mark related RXXX as `deprecated`
- Remove abandoned design elements from SPECIFICATIONS
- Commit: `"docs: remove abandoned <feature-name> from PROJECT.md"`

### 6. Generate/Update README.md

**When:** Called automatically by Operation 1 (after creating PROJECT.md) and Operation 4 (after registering a feature). Can also be invoked manually.

README.md lives in the source code git repo root (not `docs/superpowers/`). In projects where `src/` is its own git repo, write there.

Read `references/readme-template.md` for the full template, auto-detection sources, and merge rules.

Steps:

1. Read PROJECT.md — extract project name, SPECIFICATIONS (Overview, Tech Stack, Source Structure, Architecture, Development Setup including Test), and FEATURES
2. Locate the source code git repo root
3. Read existing README.md from source repo (if exists) — extract `## Additional` section content to preserve
4. Auto-detect prerequisites/install/run/test from source repo project files (see template reference for detection sources)
5. Merge: PROJECT.md `### Development Setup` values take precedence over auto-detected values; auto-detected fills gaps
6. If Installation, Running, or Testing sections would still be empty, ask the developer for the missing commands and store in PROJECT.md `### Development Setup`
7. Render README from template
8. Write README.md to source repo root
9. Commit in source repo: `"docs: update README.md"`

## ID Assignment

- **RXXX**: sequential from R001. Scan existing REQUIREMENTS table for highest ID, increment.
- **FXXX**: sequential from F001. Scan existing FEATURES table for highest ID, increment.
- Never reuse IDs — deprecated requirements keep their numbers.

## Key Principles

- SPECIFICATIONS is technical and terse — bullet points, tables, mermaid diagrams. Minimal prose, only where necessary for clarity.
- STATE is transient — presence means "in progress", absence means "done or abandoned".
- Not every spec detail is a requirement. "Use localStorage, no backend" constrains future work (requirement). "Tasks displayed in a list" describes what code does (spec detail). Apply the litmus test: would contradicting this need flagging?
- Conflict check is advisory, not blocking — user always decides.
