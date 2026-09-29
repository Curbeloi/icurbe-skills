# The right answer to eval 6: reuse business_days_between.
FIXTURE=6-py-reuse-business-days
CHECK=6
change() {
  cat > app/orders/report.py <<'PY'
from app.orders.models import Order
from app.utils.dates import business_days_between


def late_orders(orders: list[Order]) -> list[dict]:
    """Delivered orders that arrived after the promised date, with the business days late."""
    rows = []
    for order in orders:
        if order.delivered_date and order.delivered_date > order.promised_date:
            days_late = business_days_between(order.promised_date, order.delivered_date)
            rows.append({"id": order.id, "customer": order.customer, "business_days_late": days_late})
    return rows
PY
}
expect() { expect_no_red; expect_quiet_section 6; expect_quiet_section 7; expect_checks PPPPP; }
