from parse import parse_rows
from report import monthly_totals, yearly_totals

CSV = """
01.01.2026, OPENING, 1200.00
14.01.2026, groceries, -80.50
03.02.2026, salary, 4200.00
19.02.2026, rent, -1500.00
"""


def test_yearly_totals_sums_every_row():
    assert yearly_totals(parse_rows(CSV)) == {"2026": 3819.50}


def test_monthly_totals_buckets_every_row_by_month():
    assert monthly_totals(parse_rows(CSV)) == {"2026-01": 1119.50, "2026-02": 2700.00}
