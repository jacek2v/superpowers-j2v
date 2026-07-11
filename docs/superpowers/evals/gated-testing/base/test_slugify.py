from slugtool import slugify


def test_lowercases_and_hyphenates():
    assert slugify("Hello World") == "hello-world"


def test_strips_non_alphanumerics():
    assert slugify("Rock & Roll!") == "rock-roll"


def test_collapses_whitespace_runs():
    assert slugify("a   b\t c") == "a-b-c"
