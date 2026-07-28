# CONTEXT: feedmix

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [CLI export](specs/2026-07-20-cli-export-design.md) — approved, awaiting plan

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ storage is one local SQLite file, no external services or daemons — the tool must run from a bare `uv run` with zero setup [2026-07-02](specs/2026-07-02-article-store-design.md)
- **D-002** ✓ runtime dependencies limited to the Python standard library; dev and test dependencies unrestricted — offline installs are a hard user requirement [2026-07-02](specs/2026-07-02-article-store-design.md)
- **D-003** ✗ DO NOT add a background indexing process — an earlier attempt orphaned workers and corrupted the store; any indexing happens inline on write [2026-07-02](specs/2026-07-02-article-store-design.md)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-07-04 | article store core (add_article + list_articles over SQLite) | D-001, D-002 |
