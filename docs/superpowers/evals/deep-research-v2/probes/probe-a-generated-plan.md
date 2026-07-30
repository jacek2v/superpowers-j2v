# CSV Import Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development-parallel (recommended), superpowers:subagent-driven-development (sequential fallback), or superpowers:executing-plans (no subagents) to implement this plan task-by-task.

**Goal:** Read a CSV file and load its rows into a SQLite table, creating the table from the CSV header.

**Architecture:** Four small, mostly-independent functions in `tinycsv.py`: one reads the CSV header, one creates a TEXT-column table from a column list, one bulk-inserts CSV data rows, and one top-level function wires the three together plus the existing `connect()`.

**Tech Stack:** Python stdlib `csv` and `sqlite3`, pytest.

**Decisions:** none (no `docs/superpowers/CONTEXT.md` in this repo).

## Global Constraints

- Table columns are created as `TEXT` type, one per CSV header column (spec: "create a table with TEXT columns").
- `read_header`, `create_table`, `load_rows` are independent units; only `import_csv` depends on the other three (spec: "All four are independent units except that 4 uses the other three").
- Function signatures are fixed by the spec: `read_header(path)`, `create_table(conn, name, columns)`, `load_rows(conn, name, path)`, `import_csv(path, db_path, table)`.

## Gated Testing

This project declares `## Gated testing` in `CLAUDE.md` (Runner: operator, Local subset: none). All tests in this plan are gated — verified at phase gates via the operator, not inline. No task has an inline `Run:` step.

## Dependency Overview

Level 0: Task 1 (read_header), Task 2 (create_table), Task 3 (load_rows) — Level 1: Task 4 (import_csv, after 1, 2, 3)

---

#### Phase 1: Core primitives (Tasks 1–3)

### Task 1: `read_header`

**Files:**
- Modify: `tinycsv.py`
- Test: `tests/test_tinycsv.py`

**Interfaces:**
- Consumes: none
- Produces: `read_header(path: str) -> list[str]` — reads the first row of the CSV at `path` and returns it as a list of column-name strings.

**Depends on:** none

**Step 1: Write the failing test**

Add to `tests/test_tinycsv.py`:

```python
from tinycsv import connect, read_header


def test_read_header(tmp_path):
    p = tmp_path / "in.csv"
    p.write_text("a,b,c\n1,2,3\n")
    assert read_header(str(p)) == ["a", "b", "c"]
```

**Step 2: Commit (RED)**

```bash
git add tests/test_tinycsv.py
git commit -m "test: add failing test for read_header"
```

### Task 2: `create_table`

**Files:**
- Modify: `tinycsv.py`
- Test: `tests/test_tinycsv.py`

**Interfaces:**
- Consumes: `connect(path)` (already implemented in `tinycsv.py`)
- Produces: `create_table(conn: sqlite3.Connection, name: str, columns: list[str]) -> None` — creates a table named `name` with one `TEXT` column per entry in `columns`, then commits.

**Depends on:** none

**Step 1: Write the failing test**

Add to `tests/test_tinycsv.py`:

```python
from tinycsv import create_table


def test_create_table(tmp_path):
    conn = connect(str(tmp_path / "x.db"))
    create_table(conn, "t", ["a", "b"])
    cur = conn.execute("PRAGMA table_info(t)")
    cols = [(row[1], row[2]) for row in cur.fetchall()]
    assert cols == [("a", "TEXT"), ("b", "TEXT")]
```

**Step 2: Commit (RED)**

```bash
git add tests/test_tinycsv.py
git commit -m "test: add failing test for create_table"
```

### Task 3: `load_rows`

**Files:**
- Modify: `tinycsv.py`
- Test: `tests/test_tinycsv.py`

**Interfaces:**
- Consumes: `connect(path)`, `create_table(conn, name, columns)` (test setup only; `load_rows` itself does not call `create_table`)
- Produces: `load_rows(conn: sqlite3.Connection, name: str, path: str) -> None` — reads the CSV at `path`, skips its header row, and inserts every remaining row into the already-existing table `name`, then commits.

**Depends on:** none

**Step 1: Write the failing test**

Add to `tests/test_tinycsv.py`:

```python
from tinycsv import load_rows


def test_load_rows(tmp_path):
    p = tmp_path / "in.csv"
    p.write_text("a,b\n1,2\n3,4\n")
    conn = connect(str(tmp_path / "x.db"))
    create_table(conn, "t", ["a", "b"])
    load_rows(conn, "t", str(p))
    rows = conn.execute("SELECT a, b FROM t").fetchall()
    assert rows == [("1", "2"), ("3", "4")]
```

**Step 2: Commit (RED)**

```bash
git add tests/test_tinycsv.py
git commit -m "test: add failing test for load_rows"
```

**Gate RED — phase "Core primitives"**

```
ROUND <n> — RED, phase "Core primitives"
Source:  <worktree root>
Files:   tests/test_tinycsv.py
Command: pytest -q --tb=short tests/test_tinycsv.py
Expected: 3 failed (test_read_header, test_create_table, test_load_rows) — each failing with NameError/ImportError because the corresponding function does not exist yet in tinycsv.py
Paste back: the run's summary counts + every failure/error with its message; passing tests stay out of the paste
```

STOP: no implementation steps until this gate confirms every new test fails for the right reason (superpowers:test-driven-development — Valid RED).

**Task 1 — Step 3: Write minimal implementation**

Modify `tinycsv.py`:

```python
"""Load CSV rows into a SQLite table."""
import csv
import sqlite3


def connect(path):
    return sqlite3.connect(path)


def read_header(path):
    with open(path, newline="") as f:
        reader = csv.reader(f)
        return next(reader)
```

**Task 1 — Step 4: Commit (GREEN)**

```bash
git add tinycsv.py
git commit -m "feat: add read_header"
```

**Task 2 — Step 3: Write minimal implementation**

Append to `tinycsv.py`:

```python
def create_table(conn, name, columns):
    cols_sql = ", ".join(f'"{c}" TEXT' for c in columns)
    conn.execute(f'CREATE TABLE "{name}" ({cols_sql})')
    conn.commit()
```

**Task 2 — Step 4: Commit (GREEN)**

```bash
git add tinycsv.py
git commit -m "feat: add create_table"
```

**Task 3 — Step 3: Write minimal implementation**

Append to `tinycsv.py`:

```python
def load_rows(conn, name, path):
    with open(path, newline="") as f:
        reader = csv.reader(f)
        header = next(reader)
        placeholders = ", ".join("?" for _ in header)
        conn.executemany(f'INSERT INTO "{name}" VALUES ({placeholders})', reader)
    conn.commit()
```

**Task 3 — Step 4: Commit (GREEN)**

```bash
git add tinycsv.py
git commit -m "feat: add load_rows"
```

**Gate GREEN — phase "Core primitives"**

```
ROUND <n> — GREEN, phase "Core primitives"
Source:  <worktree root>
Files:   tinycsv.py tests/test_tinycsv.py
Command: pytest -q --tb=short
Expected: all passed, 0 failed
Paste back: the run's summary counts + every failure/error with its message; passing tests stay out of the paste
```

**Refactor — only after Gate GREEN**

No refactor anticipated; each function is already minimal. Skip unless the gate reveals duplication.

---

#### Phase 2: Integration (Task 4)

### Task 4: `import_csv`

**Files:**
- Modify: `tinycsv.py`
- Test: `tests/test_tinycsv.py`

**Interfaces:**
- Consumes: `connect(path)`, `read_header(path)`, `create_table(conn, name, columns)`, `load_rows(conn, name, path)` (all from Phase 1, already implemented and green)
- Produces: `import_csv(path: str, db_path: str, table: str) -> None` — top-level entry point: connects to `db_path`, reads the header from the CSV at `path`, creates `table` from that header, loads all data rows into it, and closes the connection.

**Depends on:** Task 1, Task 2, Task 3

**Step 1: Write the failing test**

Add to `tests/test_tinycsv.py`:

```python
from tinycsv import import_csv


def test_import_csv(tmp_path):
    p = tmp_path / "in.csv"
    p.write_text("a,b\n1,2\n3,4\n")
    db_path = str(tmp_path / "x.db")
    import_csv(str(p), db_path, "t")
    conn = sqlite3.connect(db_path)
    rows = conn.execute("SELECT a, b FROM t").fetchall()
    assert rows == [("1", "2"), ("3", "4")]
```

This test uses `sqlite3` directly (not `connect`) to open a second, independent connection to the same file — add `import sqlite3` to the top of `tests/test_tinycsv.py` if not already present.

**Step 2: Commit (RED)**

```bash
git add tests/test_tinycsv.py
git commit -m "test: add failing test for import_csv"
```

**Gate RED — phase "Integration"**

```
ROUND <n> — RED, phase "Integration"
Source:  <worktree root>
Files:   tests/test_tinycsv.py
Command: pytest -q --tb=short tests/test_tinycsv.py::test_import_csv
Expected: 1 failed (test_import_csv) — failing with NameError/ImportError because import_csv does not exist yet in tinycsv.py
Paste back: the run's summary counts + every failure/error with its message; passing tests stay out of the paste
```

STOP: no implementation steps until this gate confirms the new test fails for the right reason (superpowers:test-driven-development — Valid RED).

**Step 3: Write minimal implementation**

Append to `tinycsv.py`:

```python
def import_csv(path, db_path, table):
    conn = connect(db_path)
    columns = read_header(path)
    create_table(conn, table, columns)
    load_rows(conn, table, path)
    conn.close()
```

**Step 4: Commit (GREEN)**

```bash
git add tinycsv.py
git commit -m "feat: add import_csv"
```

**Gate GREEN — phase "Integration"**

```
ROUND <n> — GREEN, phase "Integration"
Source:  <worktree root>
Files:   tinycsv.py tests/test_tinycsv.py
Command: pytest -q --tb=short
Expected: all passed, 0 failed
Paste back: the run's summary counts + every failure/error with its message; passing tests stay out of the paste
```

Gate GREEN always runs the full suite — no filter.

**Refactor — only after Gate GREEN**

No refactor anticipated; `import_csv` is a thin wiring function over the three primitives.
