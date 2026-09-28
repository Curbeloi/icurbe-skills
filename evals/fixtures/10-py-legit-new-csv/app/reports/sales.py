from dataclasses import dataclass


@dataclass
class Sale:
    date: str
    customer: str
    product: str
    amount: float


@dataclass
class ReportRow:
    customer: str
    orders: int
    total: float


def build_sales_report(sales: list[Sale]) -> list[ReportRow]:
    """Groups sales by customer, largest total first."""
    by_customer: dict[str, ReportRow] = {}
    for s in sales:
        row = by_customer.setdefault(s.customer, ReportRow(s.customer, 0, 0.0))
        row.orders += 1
        row.total += s.amount
    return sorted(by_customer.values(), key=lambda r: r.total, reverse=True)


def render_text(rows: list[ReportRow]) -> str:
    return "\n".join(f"{r.customer:<20}{r.orders:>5}{r.total:>12.2f}" for r in rows)
