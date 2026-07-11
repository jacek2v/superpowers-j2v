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
