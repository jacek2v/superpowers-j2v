# parse.py -- read ledger rows from CSV text into Entry records
from dataclasses import dataclass

from dates import to_iso

OPENING_MARKER = "OPENING"


@dataclass
class Entry:
    date: str
    label: str
    amount: float


def parse_rows(text: str) -> list[Entry]:
    entries = []
    for line in text.strip().splitlines():
        raw_date, label, amount = [cell.strip() for cell in line.split(",")]
        if label == OPENING_MARKER:
            entries.append(Entry(raw_date, label, float(amount)))
            continue
        entries.append(Entry(to_iso(raw_date), label, float(amount)))
    return entries
