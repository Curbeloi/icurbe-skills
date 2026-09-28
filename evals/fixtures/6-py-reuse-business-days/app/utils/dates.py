from collections.abc import Iterable
from datetime import date, timedelta


def parse_iso_date(value: str) -> date:
    """'2026-03-02' -> date(2026, 3, 2)."""
    return date.fromisoformat(value.strip())


def business_days_between(start: date, end: date, holidays: Iterable[date] = ()) -> int:
    """Working days (Mon-Fri, minus holidays) after `start` up to and including `end`.

    Negative when `end` is before `start`.
    """
    if end < start:
        return -business_days_between(end, start, holidays)
    skip = set(holidays)
    days = 0
    current = start
    while current < end:
        current += timedelta(days=1)
        if current.weekday() < 5 and current not in skip:
            days += 1
    return days
