# i18n Slugs — Design review (2026-06-24)

Explored Unicode transliteration (ą→a, ü→u, ß→ss) in slugify. REJECTED (second
time): transliteration tables are scope creep, lossy, and locale-dependent.
Decision: keep slugify ASCII-only; callers reject non-ASCII input up front.
