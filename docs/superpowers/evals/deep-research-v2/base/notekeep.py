# notekeep.py -- toy single-device note store for deep-research evals
import sqlite3

DB_PATH = "notekeep.db"


def connect(path: str = DB_PATH) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS notes ("
        "id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL, "
        "updated_at TEXT NOT NULL DEFAULT (datetime('now')))"
    )
    return conn


def add_note(conn: sqlite3.Connection, title: str, body: str) -> int:
    cur = conn.execute("INSERT INTO notes (title, body) VALUES (?, ?)", (title, body))
    conn.commit()
    return cur.lastrowid


def edit_note(conn: sqlite3.Connection, note_id: int, body: str) -> None:
    conn.execute(
        "UPDATE notes SET body = ?, updated_at = datetime('now') WHERE id = ?",
        (body, note_id),
    )
    conn.commit()


def list_notes(conn: sqlite3.Connection) -> list[tuple[int, str]]:
    return list(conn.execute("SELECT id, title FROM notes ORDER BY id"))
