# Note Store — Design (2026-07-05)

`connect(path)` opens one local SQLite file and creates the `notes` table
(`id`, `title`, `body`, `updated_at`) if missing. `add_note(conn, title,
body) -> int` inserts and returns the row id; `edit_note(conn, note_id,
body)` updates the body and refreshes `updated_at`; `list_notes(conn)`
returns `(id, title)` in insertion order. Each device keeps its own local
file and works fully offline; there is no sync between devices yet.
