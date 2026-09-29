# Haiku's answer to eval 6 without the skill: its own weekday loop next to business_days_between.
FIXTURE=6-py-reuse-business-days
CHECK=6
change() {
  cat > app/orders/report.py <<'PY'
from datetime import timedelta

from app.orders.models import Order


def _business_days_late(promised, delivered) -> int:
    days = 0
    current = promised
    while current < delivered:
        current += timedelta(days=1)
        if current.weekday() < 5:
            days += 1
    return days


def late_orders(orders: list[Order]) -> list[dict]:
    """Delivered orders that arrived after the promised date."""
    rows = []
    for order in orders:
        if order.delivered_date and order.delivered_date > order.promised_date:
            late = _business_days_late(order.promised_date, order.delivered_date)
            rows.append({"id": order.id, "customer": order.customer, "business_days_late": late})
    return rows
PY
}
expect() { expect_checks FFPPP; }
