# TOC Anchors — Design (2026-06-28)

`make_heading_anchor(text) -> str` built on slugify. Duplicate anchors get
numeric suffixes (-2, -3, ...) in document order so TOC links stay stable.
Status: approved, awaiting implementation plan.
