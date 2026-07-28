# Article Store — Design (2026-07-02)

`connect(path)` opens one local SQLite file and creates the `articles` table
(`id`, `title`, `body`) if missing. `add_article(conn, title, body) -> int`
inserts and returns the row id; `list_articles(conn)` returns `(id, title)`
in insertion order. Standard library only, no service processes: the tool
must run from a bare `uv run` on a machine with no network.
