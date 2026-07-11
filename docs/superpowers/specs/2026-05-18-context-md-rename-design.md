# Rename PROJECT.md → CONTEXT.md and restructure project-registry skill — Design

**Date:** 2026-05-18
**Status:** Approved (design)
**Scope:** `superpowers-j2v.git` fork only; not upstream
**Affected skills:** `project-registry`, `brainstorming`, `writing-plans`, `executing-plans`, `subagent-driven-development`

---

## 1. Context & Problem

The `project-registry` skill maintains `docs/superpowers/PROJECT.md` as a four-section registry (`SPECIFICATIONS`, `STATE`, `REQUIREMENTS`, `FEATURES`). Over time three problems have surfaced:

- **`SPECIFICATIONS` duplicates content with the source repo README** — overview, tech stack, architecture, source structure live in both files and drift. This forces re-synthesis of SPECIFICATIONS on every spec update (Op 2) and on feature register (Op 4 — "Update SPECIFICATIONS if implementation diverged").
- **`PROJECT.md` is misnamed for its true role** — the file is AI-workspace context (STATE of in-progress work, RXXX constraints emerging from specs), not "the project document". The name suggests human-facing project documentation, which causes content to bleed in (the SPECIFICATIONS section).
- **Internal inconsistency in the upstream ecosystem** — `grill-with-docs` and `improve-codebase-architecture` already read `CONTEXT.md`, while `project-registry`, `brainstorming`, `writing-plans`, `executing-plans`, and `subagent-driven-development` write/read `PROJECT.md`. Two file names for what is conceptually one role.

The originating design (`~/prjs/<gated project>/docs/superpowers/specs/2026-05-18-documentation-consolidation-design.md`, decision D2) addresses the duplication problem in one project (<gated project>). This spec ports the **skill-level changes** required to make that pattern the default in this fork.

### Goal

Rename `PROJECT.md` → `CONTEXT.md`, drop `SPECIFICATIONS` from the file (source repo README is the source of truth), restructure `REQUIREMENTS` and `FEATURES` for human readability, and propagate the rename through every consumer skill in the fork. Remove Operation 6 (README generation) because the skill is no longer the source of truth for README content.

## 2. Decisions

### D1 — Hardcoded rename `PROJECT.md` → `CONTEXT.md` (option A), not configurable per project

**Decision:** the file name `CONTEXT.md` is hardcoded in all skill files. No per-project configuration.

**Rationale:**

- This is a personal fork — no external users requiring backwards compatibility.
- Structural changes (drop `SPECIFICATIONS`, reformat `REQUIREMENTS`/`FEATURES`) already break compatibility with old `PROJECT.md` files. A filename flag would preserve the name, not the structure — half-compat is worse than full migration.
- Configurability adds permanent complexity (every operation reads config, every template uses placeholders) for a one-time per-project migration concern.
- Consistency with upstream — `grill-with-docs` and `improve-codebase-architecture` already use `CONTEXT.md`.
- YAGNI (per user's CLAUDE.md: "don't add abstractions beyond what the task requires").

### D2 — Drop `SPECIFICATIONS` section from `CONTEXT.md`

**Decision:** the section is removed entirely. Source repo `README.md` (and optionally `STATUS.md`, `OPERATIONS.md`) is the single source of truth for: overview, tech stack, architecture, source structure, key strategic decisions, development setup.

**Rationale:** dual-write to two source-of-truth files leads to drift. `CONTEXT.md` is for AI-workspace metadata (specs in flight, RXXX constraints, FXXX index) — not project facts.

**Consequence:** `CONTEXT.md` adds a top-level `## Source of truth` section linking to the source repo files. Synchronization is unidirectional — when source repo content changes, `CONTEXT.md`'s STATE/REQUIREMENTS sections may update; never the reverse.

### D3 — `REQUIREMENTS` reformatted from table to flat list grouped by spec

**Decision:** the `| ID | Requirement | Rationale | Status | Features |` table is replaced by:

```markdown
### R-001 .. R-00N (YYYY-MM-DD) — <feature name>
*Spec: [`YYYY-MM-DD-feature-design.md`](specs/YYYY-MM-DD-feature-design.md)*

- **R-001** <1–3 sentences>
- **R-002** <1–3 sentences>
```

**Rationale:** R-XXX entries arrive as a group per spec. A grouped list lets each requirement breathe (1–3 sentences instead of a single table cell), links to the originating spec once per group, and reads top-to-bottom as a chronological history of constraints accumulated.

### D4 — Status of `R-XXX` derived, not stored inline

**Decision:** the `Status` column is removed. Status is computed:

| Derived state | Source |
|---|---|
| `in-progress` | the R-XXX's originating spec is listed in `STATE` |
| `implemented` | the R-XXX is listed in the `Requirements` column of any `F-XXX` in `FEATURES` |
| `active` (accepted, not yet shipped) | neither of the above; not deprecated |
| `deprecated` | explicit inline marker on the entry |

**Deprecated marker format:**

```markdown
- **R-001** ~~<description>~~ [deprecated YYYY-MM-DD, superseded by R-NNN]
```

**Rationale:** status was previously updated in multiple places (the requirement row + the feature row's RXXX list). Deriving from STATE/FEATURES removes the duplication. Conflict-check (Op 3) iterates `FEATURES` to find implemented R-XXX instead of scanning a `Status` column.

### D5 — `FEATURES` reformatted as index table, no prose

**Decision:** the `| ID | Feature | Date | Requirements |` table is preserved structurally but each `Feature` cell is a 1-line description (not a prose paragraph), and a `Spec` link column is added:

```markdown
| ID    | Description           | Requirements   | Spec                          |
|-------|-----------------------|----------------|-------------------------------|
| F-001 | <1-line description>  | R-001, R-002   | [link](specs/YYYY-MM-DD-…)    |
```

**Rationale:** feature details (prose, diagrams, full description) live in the source repo (README features list, CHANGELOG, or STATUS.md release notes). `CONTEXT.md`'s FEATURES section is an index into the AI-workspace specs/, used for the cross-reference R-XXX↔F-XXX needed by Op 3 (conflict check) and Op 4 (feature register).

### D6 — Remove Operation 6 (Generate/Update README.md) entirely

**Decision:** Op 6 is removed from `project-registry`. `references/readme-template.md` is deleted. The skill no longer touches source repo README files.

**Rationale:** Op 6 generated README from `PROJECT.md` `SPECIFICATIONS`. With SPECIFICATIONS removed (D2), the generation source is gone — README is now the source of truth for what Op 6 used to generate. Three alternatives were considered:

- **α (chosen):** remove Op 6. README hand-authored per project conventions.
- β: stub README on initial create, no updates — minimal value, residual confusion about "what generates what".
- γ: Op 6 syncs FEATURES section from `CONTEXT.md` to README — creates duplicate source-of-truth for feature listings (one in CONTEXT.md, one synced to README), violating D2's principle.

Rejected β and γ both add complexity without solving a problem the user has.

**Consequence:** any project upgrading to the new model authors its own README. The skill's responsibility is `CONTEXT.md` only.

### D7 — Full propagation scope: 7 files across 5 skills

**Decision:** the rename and structural changes propagate to every skill in the fork that references `PROJECT.md`.

| Skill | File | Change |
|---|---|---|
| project-registry | `SKILL.md` | Full rewrite of operations (rename + Op 1/2/4/5 simplifications + Op 6 removal) |
| project-registry | `references/project-template.md` | Full rewrite (new structure) |
| project-registry | `references/readme-template.md` | **Delete** |
| brainstorming | `SKILL.md` | Rename (13 refs); rewrite of step 12 ("update SPECIFICATIONS prose" → drop); flowchart node labels |
| writing-plans | `SKILL.md` | Rename (4 refs); drop "SPECIFICATIONS (current architecture)" from context-loading step |
| executing-plans | `SKILL.md` | Rename (3 refs); remove line "Update SPECIFICATIONS if implementation diverged" |
| subagent-driven-development | `SKILL.md` | Rename (1 ref) |

**Rationale:** partial rename (project-registry only) would leave consumer skills referring to `PROJECT.md` while the registry skill creates `CONTEXT.md` — broken state worse than either current or fully migrated.

## 3. Design

### 3.1 New `references/project-template.md`

```markdown
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
```

### 3.2 New `SKILL.md` (project-registry) — operations spec

**Frontmatter description** (one sentence): replace all `PROJECT.md` with `CONTEXT.md`. Remove the clause "Also generates/updates README.md in the source code repo" and the mention of README in invocation contexts.

**`## CONTEXT.md Structure`** (replaces `## PROJECT.md Structure`):

> Three sections, in order:
>
> 1. **STATE** — specs currently in development, with links. Entries appear after brainstorming, disappear when feature ships.
> 2. **REQUIREMENTS** — numbered R-XXX, grouped by originating spec. Developer decisions that constrain future work. Litmus test: "If a future feature contradicted this, would it need flagging?" Yes → requirement. No → implementation detail (lives in spec/code, not here).
> 3. **FEATURES** — numbered F-XXX. Added when implementation ships. Index table with R-XXX cross-reference and spec link.
>
> Plus a top-level `## Source of truth` section linking to source repo files.
>
> For the initial template, read `references/project-template.md`.

**Operations (re-spec, summarized):**

- **Op 1 (Create CONTEXT.md):**
  - Read approved spec.
  - Render template; populate `## Source of truth` with the source repo's README path. Include rows for `STATUS.md` and `OPERATIONS.md` only if those files exist in the source repo at creation time.
  - Add spec link to STATE.
  - Extract constraining decisions from spec → assign R-001, R-002 with 1–3 sentence summary, group under `### R-001 .. R-00N (YYYY-MM-DD) — <feature name>` heading, link to spec.
  - FEATURES table empty.
  - Commit: `docs: create CONTEXT.md with initial spec registry`.

- **Op 2 (Update for new spec):**
  - Read current CONTEXT.md and new approved spec.
  - STATE: append new spec link.
  - REQUIREMENTS: append a new `### R-NNN .. R-MMM (YYYY-MM-DD) — <feature name>` group; assign next R-IDs.
  - Commit: `docs: update CONTEXT.md with <feature-name> spec`.

- **Op 3 (Conflict check):**
  - Read CONTEXT.md.
  - Build derived status:
    - `implemented R-XXX` = those listed in any FEATURES row's Requirements column.
    - `in-progress R-XXX` = those whose originating spec is in STATE.
    - `deprecated R-XXX` = those marked `[deprecated …]` inline.
  - For each `implemented` R-XXX: does the proposed design modify the behaviour it describes? If yes → flag (cite F-XXX too).
  - For each `in-progress` R-XXX: does the proposed design contradict it? If yes → flag.
  - Check STATE for overlapping in-flight specs.
  - Present flags in the existing format (`⚠ Conflict check against CONTEXT.md: ...`).

- **Op 4 (Register feature):**
  - Remove the spec entry from STATE.
  - Append F-XXX row to FEATURES with: date, 1-line description, comma-separated R-XXX it satisfies, spec link.
  - Commit: `docs: register F-XXX <feature-name> in CONTEXT.md`.
  - **No more "Mark R-XXX as implemented"** — status is derived.
  - **No more "Update SPECIFICATIONS if diverged"** — section doesn't exist.
  - **No more Op 6 trigger** — README is not managed by this skill.

- **Op 5 (Cleanup abandoned spec):**
  - Remove spec entry from STATE.
  - Mark relevant R-XXX entries with the deprecated marker `~~<text>~~ [deprecated YYYY-MM-DD, abandoned]`.
  - Commit: `docs: remove abandoned <feature-name> from CONTEXT.md`.

- **Op 6 (Generate/Update README.md):** **removed.**

**`## ID Assignment`:**

- **R-XXX**: sequential from R-001. Scan all `### R-N .. R-M …` group headings in REQUIREMENTS for the highest ID, increment.
- **F-XXX**: sequential from F-001. Scan FEATURES table for the highest ID, increment.
- Never reuse IDs — deprecated entries keep their numbers.

**`## Key Principles`:**

- STATE is transient — presence means "in progress", absence means "done or abandoned".
- Not every spec detail is a requirement. Apply the litmus test.
- Conflict check is advisory, not blocking — user always decides.
- Status of R-XXX is derived from STATE (in-progress) and FEATURES (implemented). Only `[deprecated]` is explicit.
- This skill manages `CONTEXT.md` only. It does not touch source repo files (README, STATUS, OPERATIONS).

### 3.3 `references/readme-template.md` — deleted

Removed from the skill bundle. No replacement.

### 3.4 Changes to consumer skills

**`brainstorming/SKILL.md`:**

- Replace `PROJECT.md` → `CONTEXT.md` everywhere (13 occurrences in body + DOT graph node labels + step text).
- Step 2 ("Project registry check"): path becomes `docs/superpowers/CONTEXT.md`.
- Step 8 ("Conflict check"): path becomes `docs/superpowers/CONTEXT.md`.
- Step 12 ("Update PROJECT.md"): rewrite as "Update CONTEXT.md — create or update using project-registry skill (operations 1 or 2): add spec to STATE, register new R-XXX requirements. Commit." (drop "update SPECIFICATIONS prose").
- DOT graph: rename node `"Update PROJECT.md\n(SPECIFICATIONS + STATE + REQUIREMENTS)"` → `"Update CONTEXT.md\n(STATE + REQUIREMENTS)"`. Similar for other graph nodes.
- Section header `**Update PROJECT.md:**` → `**Update CONTEXT.md:**`. Body: "If `docs/superpowers/CONTEXT.md` does not exist → create it (operation 1) …".

**`writing-plans/SKILL.md`:**

- Line 29: replace `docs/superpowers/PROJECT.md if it exists — for SPECIFICATIONS (current architecture) and REQUIREMENTS (RXXX constraints)` → `docs/superpowers/CONTEXT.md if it exists — for REQUIREMENTS (RXXX constraints)`.
- Line 31: replace `PROJECT.md` → `CONTEXT.md`.
- Line 68: replace `RXXX entries from PROJECT.md` → `RXXX entries from CONTEXT.md`.
- Line 148: replace `PROJECT.md` → `CONTEXT.md` (both occurrences in that line).

**`executing-plans/SKILL.md`:**

- Line 35–39 (Step 3 — Register Feature): keep "Add FXXX entry to FEATURES with date and list of satisfied RXXX". **Remove** lines "Mark those RXXX as `implemented`" and "Update SPECIFICATIONS if implementation diverged". Replace "Commit PROJECT.md changes" with "Commit CONTEXT.md changes".
- Line 43: replace `PROJECT.md` → `CONTEXT.md`.
- Line 79: replace `Register completed feature in PROJECT.md` → `Register completed feature in CONTEXT.md`.

**`subagent-driven-development/SKILL.md`:**

- Line 280: replace `PROJECT.md` → `CONTEXT.md`.

## 4. New requirements

This change is to the skill repo itself (`superpowers-j2v.git`). The repo does not currently maintain its own `CONTEXT.md` registry — the user has not asked for one. The constraining decisions established by this design (D1–D7 above) are recorded in this spec, not in a registry. If the user later decides to create `docs/superpowers/superpowers-j2v/CONTEXT.md` for the skill fork, these decisions promote into R-XXX entries at that time.

Notable invariants future work on the skill should respect (would become R-XXX if a registry existed):

- **I-1** `CONTEXT.md` is the canonical file name across all consumer skills. Per-project configurability is rejected as YAGNI.
- **I-2** `CONTEXT.md` has exactly three content sections: STATE, REQUIREMENTS, FEATURES — plus a top-level `## Source of truth` pointer block. No SPECIFICATIONS.
- **I-3** R-XXX status is derived from STATE (in-progress) and FEATURES (implemented). Only `[deprecated]` is stored inline.
- **I-4** The `project-registry` skill manages `CONTEXT.md` only. It does not generate, update, or touch source repo files (README, STATUS, OPERATIONS).

## 5. Migration plan (overview — detailed plan separate)

Phase 1: rewrite `project-registry/SKILL.md` and `project-registry/references/project-template.md` with the new structure and operations. Delete `project-registry/references/readme-template.md`.

Phase 2: propagate the rename through `brainstorming/SKILL.md`, `writing-plans/SKILL.md`, `executing-plans/SKILL.md`, `subagent-driven-development/SKILL.md` per the diffs in §3.4.

Phase 3: validation — read each modified skill end-to-end; verify no remaining `PROJECT.md` references; verify cross-references (e.g., brainstorming step 12 invokes the right operation names) still align with the new project-registry operations.

Phase 4: commit each phase separately for reviewability. No source repo (<gated project> or other) is touched as part of this work — those migrate independently.

Detailed phase-by-phase plan with file-level diffs deferred to the implementation plan (separate document via writing-plans skill).

## 6. Out of scope

- Migration of any existing `PROJECT.md` file in user's other projects (<gated project>, etc.) — handled per-project, manually.
- Changes to upstream `superpowers` plugin — this is a fork-only change. No PR upstream.
- Changes to skills NOT referencing `PROJECT.md`: `dispatching-parallel-agents`, `finishing-a-development-branch`, `receiving-code-review`, `requesting-code-review`, `systematic-debugging`, `test-driven-development`, `using-git-worktrees`, `using-superpowers`, `verification-before-completion`, `writing-skills`.
- Creating a `CONTEXT.md` for `superpowers-j2v.git` itself — defer until user asks.
- Test/eval evidence for the skill change — per `superpowers-j2v.git/CLAUDE.md`, that bar applies to upstream PRs; this is fork-internal.

## 7. Open questions

None outstanding. All decisions resolved during brainstorming (A vs B, scope, Op 6 fate, status derivation).
