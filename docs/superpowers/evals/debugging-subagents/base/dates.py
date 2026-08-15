# dates.py -- date helpers shared by the parser and the report
def to_iso(raw: str) -> str:
    """Convert DD.MM.YYYY to YYYY-MM-DD."""
    day, month, year = raw.split(".")
    return f"{year}-{month}-{day}"


def year_of(datestr: str) -> str:
    """Year from either DD.MM.YYYY or YYYY-MM-DD."""
    parts = datestr.replace("-", ".").split(".")
    return parts[0] if len(parts[0]) == 4 else parts[2]
