# Wordstats Implementation Plan (eval fixture)

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Tiny word-statistics CLI: tokenize text, count words, format a report.

**Architecture:** Three pure modules plus a CLI wrapper. No external dependencies.

**Tech Stack:** Python 3.11+, pytest.

## Global Constraints

- Python stdlib only; no new dependencies.
- All public functions carry type hints.

## Dependency Overview

Level 0: Tasks 1, 2 — Level 1: Task 3 (after 1, 2) — Level 2: Task 4 (after 3)

---

### Task 1: Tokenizer

**Files:**
- Create: `src/tokenize.py`
- Test: `tests/test_tokenize.py`

**Interfaces:**
- Produces: `tokenize(text: str) -> list[str]` — lowercased word tokens, punctuation stripped.

**Depends on:** none

- [ ] **Step 1: failing test** — `assert tokenize("Hi, hi!") == ["hi", "hi"]`
- [ ] **Step 2: run** `pytest tests/test_tokenize.py -v` — expect FAIL (module missing)
- [ ] **Step 3: implement** — `return re.findall(r"[a-z']+", text.lower())`
- [ ] **Step 4: run** — expect PASS
- [ ] **Step 5: commit** — `feat: add tokenizer`

### Task 2: Counter

**Files:**
- Create: `src/count.py`
- Test: `tests/test_count.py`

**Interfaces:**
- Produces: `count(tokens: list[str]) -> dict[str, int]` — token → occurrences.

**Depends on:** none

- [ ] **Step 1: failing test** — `assert count(["a", "b", "a"]) == {"a": 2, "b": 1}`
- [ ] **Step 2: run** `pytest tests/test_count.py -v` — expect FAIL (module missing)
- [ ] **Step 3: implement** — `return dict(collections.Counter(tokens))`
- [ ] **Step 4: run** — expect PASS
- [ ] **Step 5: commit** — `feat: add counter`

### Task 3: Report formatter

**Files:**
- Create: `src/report.py`
- Test: `tests/test_report.py`

**Interfaces:**
- Consumes: `tokenize(text) -> list[str]` (Task 1), `count(tokens) -> dict[str, int]` (Task 2)
- Produces: `report(text: str) -> str` — one line per word, `word: n`, descending by count.

**Depends on:** Task 1, Task 2

- [ ] **Step 1: failing test** — `assert report("b a b") == "b: 2\na: 1"`
- [ ] **Step 2: run** `pytest tests/test_report.py -v` — expect FAIL (module missing)
- [ ] **Step 3: implement** — sort `count(tokenize(text)).items()` by `-n`, join `f"{w}: {n}"` lines
- [ ] **Step 4: run** — expect PASS
- [ ] **Step 5: commit** — `feat: add report formatter`

### Task 4: CLI

**Files:**
- Create: `src/cli.py`
- Test: `tests/test_cli.py`

**Interfaces:**
- Consumes: `report(text) -> str` (Task 3)
- Produces: `main() -> None` — prints `report(sys.stdin.read())`.

**Depends on:** Task 3

- [ ] **Step 1: failing test** — monkeypatch stdin with `"b a b"`, capsys output == `"b: 2\na: 1\n"`
- [ ] **Step 2: run** `pytest tests/test_cli.py -v` — expect FAIL (module missing)
- [ ] **Step 3: implement** — `print(report(sys.stdin.read()))`
- [ ] **Step 4: run** — expect PASS
- [ ] **Step 5: commit** — `feat: add CLI`
