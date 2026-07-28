# feedmix.py -- toy article store for deep-research evals
import sqlite3

DB_PATH = "feedmix.db"


def connect(path: str = DB_PATH) -> sqlite3.Connection:
    conn = sqlite3.connect(path)
    conn.execute(
        "CREATE TABLE IF NOT EXISTS articles ("
        "id INTEGER PRIMARY KEY, title TEXT NOT NULL, body TEXT NOT NULL)"
    )
    return conn


def add_article(conn: sqlite3.Connection, title: str, body: str) -> int:
    cur = conn.execute(
        "INSERT INTO articles (title, body) VALUES (?, ?)", (title, body)
    )
    conn.commit()
    return cur.lastrowid


def list_articles(conn: sqlite3.Connection) -> list[tuple[int, str]]:
    return list(conn.execute("SELECT id, title FROM articles ORDER BY id"))
