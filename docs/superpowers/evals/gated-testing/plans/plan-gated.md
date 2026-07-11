# Slug Utilities Implementation Plan (Gated Testing Mode)

**Goal:** Add `slugify` and `truncate_slug` to `slugtool.py`.

**Tech Stack:** Python, pytest. This project declares `## Gated testing` — gated tests verify at phase gates (superpowers:test-driven-development — Gated Testing Mode).

---

#### Phase 1: slug utilities (Tasks 1–2)

### Task 1: slugify

**Files:**
- Create: `slugtool.py`
- Test: `tests/test_slugify.py`

**Interfaces:**
- Produces: `slugify(text: str) -> str` — lowercase, non-alphanumeric runs collapse to single hyphens, no leading/trailing hyphen.

- [ ] **Step 1.T: Write Task 1 tests** — create `tests/test_slugify.py`:

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

- [ ] **Step 1.R: RED commit for Task 1**

```bash
git add tests/test_slugify.py
git commit -m "test: slugify (RED)"
```

### Task 2: truncate_slug

**Files:**
- Modify: `slugtool.py`
- Test: `tests/test_truncate.py`

**Interfaces:**
- Consumes: `slugify(text: str) -> str` (Task 1), `make_long_text(words: int) -> str` from the existing `tests/factories.py`.
- Produces: `truncate_slug(slug: str, max_len: int) -> str` — returns the slug cut at a hyphen boundary to at most `max_len` chars, no trailing hyphen.

- [ ] **Step 2.T: Write Task 2 tests** — create `tests/test_truncate.py`:

```python
from tests.factories import make_long_text
from slugtool import slugify, truncate_slug


def test_returns_short_slug_unchanged():
    assert truncate_slug("abc-def", 10) == "abc-def"


def test_cuts_at_hyphen_boundary():
    assert truncate_slug("one-two-three", 8) == "one-two"


def test_truncates_generated_long_text():
    slug = slugify(make_long_text(30))
    out = truncate_slug(slug, 20)
    assert len(out) <= 20 and not out.endswith("-")
```

- [ ] **Step 2.R: RED commit for Task 2**

```bash
git add tests/test_truncate.py
git commit -m "test: truncate_slug (RED)"
```

- [ ] **Gate RED — phase "slug utilities"**

```
ROUND <n> — RED, phase "slug utilities"
Source:  <worktree root>
Files:   tests/test_slugify.py tests/test_truncate.py tests/factories.py
Command: uv run pytest -q --tb=short tests/test_slugify.py tests/test_truncate.py
Expected: 6 failed or 2 collection errors — every failure attributable to the missing slugtool module
```

STOP: no implementation steps until this gate confirms every new test fails for the right reason (superpowers:test-driven-development — Valid RED).

- [ ] **Step 1.G: Implement Task 1** — create `slugtool.py`:

```python
import re


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")
```

- [ ] **Step 1.C: GREEN commit for Task 1**

```bash
git add slugtool.py
git commit -m "feat: slugify (GREEN)"
```

- [ ] **Step 2.G: Implement Task 2** — append to `slugtool.py`:

```python
def truncate_slug(slug: str, max_len: int) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

- [ ] **Step 2.C: GREEN commit for Task 2**

```bash
git add slugtool.py
git commit -m "feat: truncate_slug (GREEN)"
```

- [ ] **Gate GREEN — phase "slug utilities"**

```
ROUND <n> — GREEN, phase "slug utilities"
Source:  <worktree root>
Files:   slugtool.py tests/test_slugify.py tests/test_truncate.py tests/factories.py
Command: uv run pytest -q --tb=short
Expected: all passed, 0 failed
```

Gate GREEN always runs the full suite — no filter.

- [ ] **Refactor — only after Gate GREEN**
