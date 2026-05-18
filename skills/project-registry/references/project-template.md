# CONTEXT.md Template

Use this template when creating CONTEXT.md for the first time.

`````markdown
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
`````
