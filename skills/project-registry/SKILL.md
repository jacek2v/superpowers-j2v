---
name: project-registry
description: "Manage PROJECT.md — the project's single source of truth for architecture, requirements, and features. Invoked by other skills: brainstorming (conflict check + register spec), subagent-driven-development and executing-plans (register completed feature). Not user-invocable directly."
---

# Project Registry

Manage `docs/superpowers/PROJECT.md` as a living registry of what the project IS, what decisions constrain it, and what has been built. This file prevents new work from silently contradicting or breaking existing features.

## PROJECT.md Structure

Four sections, in order:

1. **SPECIFICATIONS** — prose architecture summary (overview, tech stack, source structure, architecture). No tables, no links. Rewritten as a coherent narrative each time new design is incorporated.
2. **STATE** — specs currently in development, with links. Entries appear after brainstorming, disappear when feature ships.
3. **REQUIREMENTS** — numbered RXXX. Includes functional requirements, design decisions, constraints, assumptions. Everything that constrains future work.
4. **FEATURES** — numbered FXXX. Added when implementation ships. Cross-references which RXXX it satisfies.

For the initial template, read `references/project-template.md`.

## Operations

### 1. Create PROJECT.md

**When:** First brainstorming session (no PROJECT.md exists yet).

- Read the approved spec
- Populate SPECIFICATIONS from spec: overview, tech stack, source structure, architecture
- Add spec link to STATE
- Extract ALL decisions and requirements from spec → assign R001, R002, ... with status `active`
- FEATURES section empty
- Commit: `"docs: create PROJECT.md with initial spec registry"`

### 2. Update for New Spec

**When:** Brainstorming ends, PROJECT.md already exists.

- Read current PROJECT.md and the new approved spec
- SPECIFICATIONS: rewrite the section to incorporate new design into existing prose. Do NOT append — synthesize into one coherent narrative reflecting the full system.
- STATE: add new spec link
- REQUIREMENTS: assign next available RXXX IDs, status `active`
- Commit: `"docs: update PROJECT.md with <feature-name> spec"`

### 3. Conflict Check

**When:** Brainstorming starts, PROJECT.md exists.

Read PROJECT.md. After understanding the user's proposed idea, before finalizing design:

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

### 5. Cleanup Abandoned Spec

**When:** User decides to abandon in-progress work.

- Remove spec entry from STATE
- Mark related RXXX as `deprecated`
- Remove abandoned design elements from SPECIFICATIONS
- Commit: `"docs: remove abandoned <feature-name> from PROJECT.md"`

## ID Assignment

- **RXXX**: sequential from R001. Scan existing REQUIREMENTS table for highest ID, increment.
- **FXXX**: sequential from F001. Scan existing FEATURES table for highest ID, increment.
- Never reuse IDs — deprecated requirements keep their numbers.

## Key Principles

- SPECIFICATIONS is prose, never tables or link lists. It describes the system holistically.
- STATE is transient — presence means "in progress", absence means "done or abandoned".
- Every design decision IS a requirement. "Use localStorage" constrains future work the same as "User can add tasks".
- Conflict check is advisory, not blocking — user always decides.
