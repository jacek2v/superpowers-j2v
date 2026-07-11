# Slug Utilities Implementation Plan

**Goal:** Add `slugify` and `truncate_slug` to `slugtool.py`.

**Tech Stack:** Python, pytest (run via `uv run pytest`).

---

### Task 1: slugify

**Files:**
- Create: `slugtool.py`
- Test: `tests/test_slugify.py`

- [ ] **Step 1: Write the failing test** — create `tests/test_slugify.py`:

```python
from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_slugify.py`
Expected: FAIL — `ModuleNotFoundError: No module named 'slugtool'`

- [ ] **Step 3: Write minimal implementation** — create `slugtool.py`:

```python
import re


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q tests/test_slugify.py`
Expected: 3 passed

- [ ] **Step 5: Commit**

```bash
git add tests/test_slugify.py slugtool.py
git commit -m "feat: add slugify"
```

### Task 2: truncate_slug

**Files:**
- Modify: `slugtool.py`
- Test: `tests/test_truncate.py`

- [ ] **Step 1: Write the failing test** — create `tests/test_truncate.py` (uses the shared builder from `tests/factories.py`):

```python
from slugtool import slugify, truncate_slug
from tests.factories import make_long_text


def test_returns_short_slug_unchanged():
    assert truncate_slug("abc-def", 10) == "abc-def"


def test_cuts_at_hyphen_boundary():
    assert truncate_slug("one-two-three", 8) == "one-two"


def test_truncates_generated_long_text():
    slug = slugify(make_long_text(30))
    out = truncate_slug(slug, 20)
    assert len(out) <= 20 and not out.endswith("-")
```

- [ ] **Step 2: Run test to verify it fails**

Run: `uv run pytest -q tests/test_truncate.py`
Expected: FAIL — `ImportError: cannot import name 'truncate_slug'`

- [ ] **Step 3: Write minimal implementation** — append to `slugtool.py`:

```python
def truncate_slug(slug: str, max_len: int) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
```

- [ ] **Step 4: Run test to verify it passes**

Run: `uv run pytest -q`
Expected: 6 passed

- [ ] **Step 5: Commit**

```bash
git add tests/test_truncate.py slugtool.py
git commit -m "feat: add truncate_slug"
```
