# report.py -- aggregate parsed entries into monthly and yearly totals
from collections import defaultdict

from dates import year_of


def monthly_totals(entries):
    totals = defaultdict(float)
    for entry in entries:
        totals[entry.date[:7]] += entry.amount
    return dict(totals)


def yearly_totals(entries):
    totals = defaultdict(float)
    for entry in entries:
        totals[year_of(entry.date)] += entry.amount
    return dict(totals)
