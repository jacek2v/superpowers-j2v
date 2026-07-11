# CONTEXT: toyslug

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [TOC anchors](specs/2026-06-28-toc-anchors-design.md) — approved, awaiting plan

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ slugs are ASCII-only; non-ASCII input is rejected, not preserved — portability across URL consumers [2026-06-20](specs/2026-06-20-slug-core-design.md)
- **D-002** ✗ DO NOT transliterate Unicode in slugify (ą→a, ü→u) — rejected twice as scope creep; rejection beats silent mangling [2026-06-24](specs/2026-06-24-i18n-slugs-design.md)
- **D-003** ✓ max slug length = 60 (`MAX_SLUG_LEN`) — hard DB column limit `VARCHAR(60)` [2026-06-20](specs/2026-06-20-slug-core-design.md)
- **D-004** ✓ duplicate heading anchors get numeric suffixes (-2, -3) in document order — stable TOC links [2026-06-28](specs/2026-06-28-toc-anchors-design.md)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-06-22 | slugify + truncate_slug core | D-001, D-003 |
