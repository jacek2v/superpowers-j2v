# Slug Core — Design (2026-06-20)

`slugify(text) -> str`: lowercase, non-alphanumeric runs collapse to single
hyphens, no edge hyphens. ASCII-only by decision — non-ASCII input is rejected
by callers, not preserved. `truncate_slug(slug, max_len=MAX_SLUG_LEN)`: cut at
hyphen boundaries; `MAX_SLUG_LEN = 60` matches the `VARCHAR(60)` slug column.
