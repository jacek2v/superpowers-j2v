# CONTEXT: toyslug

> AI workspace metadata. Project facts (overview, architecture, tech stack,
> decisions, features) live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Project purpose, architecture, tech stack, repo map, key decisions, domain glossary | `../../README.md` |

When source repo content changes, STATE/REQUIREMENTS sections here update.
Never the reverse — source repo is the source of truth.

## STATE

Specs in development:

- [TOC anchors](specs/2026-06-28-toc-anchors-design.md) — approved, awaiting
  implementation plan. Duplicate anchors get numeric suffixes (-2, -3). During
  the i18n review on 2026-06-24 we also went over slugify internationalization
  once more and decided again NOT to pursue Unicode transliteration (ą→a, ü→u)
  in slugify — scope creep, rejected for the second time; non-ASCII input is
  rejected instead. No transliteration work is planned.

## REQUIREMENTS

Grouped by originating spec. Each R-XXX: 1–3 sentences + link to spec.
Status derived from STATE (in-progress) and FEATURES (implemented).
Explicit `[deprecated YYYY-MM-DD, superseded by R-NNN]` when retired.

### R-001 .. R-002 (2026-06-20) — slug core
*Spec: [`2026-06-20-slug-core-design.md`](specs/2026-06-20-slug-core-design.md)*

- **R-001** Slugs are ASCII-only. Non-ASCII input is rejected rather than preserved or converted, so slugs stay portable across URL consumers.
- **R-002** Maximum slug length is 60 characters (`MAX_SLUG_LEN`), matching the `VARCHAR(60)` slug column; `truncate_slug` enforces it at hyphen boundaries.

### R-003 (2026-06-28) — TOC anchors
*Spec: [`2026-06-28-toc-anchors-design.md`](specs/2026-06-28-toc-anchors-design.md)*

- **R-003** Duplicate heading anchors are disambiguated with numeric suffixes (-2, -3, ...) in document order, so TOC links stay stable when headings repeat.

## FEATURES

Index only — feature details live in source repo README/changelog.

| ID    | Description           | Requirements   | Spec                          |
|-------|-----------------------|----------------|-------------------------------|
| F-001 | slugify + truncate_slug core (2026-06-22) | R-001, R-002 | [spec](specs/2026-06-20-slug-core-design.md) |
