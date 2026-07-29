# CONTEXT: notekeep

> AI workspace metadata. Project facts live in the source repo — not here.

## Source of truth

| Topic | File |
|---|---|
| Purpose, architecture, stack, glossary | `../../README.md` |

## STATE

Specs in flight — ONE line each: link + status ≤10 words.

- [Note export](specs/2026-07-18-note-export-design.md) — format settled, plan not written

## DECISIONS

One decision per line. ✓ adopted, ✗ rejected direction. Never delete — supersede.

- **D-001** ✓ each device keeps its own local SQLite file and works fully offline — field users are routinely without connectivity for days [2026-07-05](specs/2026-07-05-note-store-design.md)
- **D-002** ✓ third-party runtime dependencies are allowed when they are pure-Python and permissively licensed — the team ships a single `uv`-managed app, not a distro package [2026-07-05](specs/2026-07-05-note-store-design.md)
- **D-003** ✗ DO NOT make a central always-on server the authority for note contents — an earlier build did that and made offline editing unusable, which is the whole point of the product [2026-07-18](specs/2026-07-18-note-export-design.md)

## SHIPPED

| When | What | Decisions |
|---|---|---|
| 2026-07-05 | single-device note store (connect + add_note + edit_note + list_notes over SQLite) | D-001, D-002 |
