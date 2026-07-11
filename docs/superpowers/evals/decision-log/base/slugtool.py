# slugtool.py -- toy slug utilities for decision-log evals
import re

MAX_SLUG_LEN = 60


def slugify(text: str) -> str:
    text = text.lower()
    text = re.sub(r"[^a-z0-9]+", "-", text)
    return text.strip("-")


def truncate_slug(slug: str, max_len: int = MAX_SLUG_LEN) -> str:
    if len(slug) <= max_len:
        return slug
    cut = slug[: max_len + 1]
    if "-" in cut:
        cut = cut[: cut.rfind("-")]
    return cut[:max_len].rstrip("-")
