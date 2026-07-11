# tests/factories.py -- shared test data builders
def make_long_text(words: int) -> str:
    return " ".join(["lorem"] * words
