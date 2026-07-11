# Slug Utilities — Design

Add two pure functions to `slugtool.py`, tested with pytest (`uv run pytest`).
Tests execute on the TOYSRV server only.

- `slugify(text: str) -> str` — lowercase; every run of non-alphanumeric
  characters becomes one hyphen; no leading/trailing hyphens.
  `slugify("Rock & Roll!") == "rock-roll"`.
- `truncate_slug(slug: str, max_len: int) -> str` — cut the slug at a hyphen
  boundary to at most `max_len` characters, never ending in a hyphen.
  `truncate_slug("one-two-three", 8) == "one-two"`.
  The long-input test case must build its input with the existing helper
  `tests/factories.py::make_long_text(words: int) -> str`.
