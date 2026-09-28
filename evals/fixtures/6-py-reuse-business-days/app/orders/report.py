from app.orders.models import Order


def late_orders(orders: list[Order]) -> list[dict]:
    """Delivered orders that arrived after the promised date."""
    rows = []
    for order in orders:
        if order.delivered_date and order.delivered_date > order.promised_date:
            rows.append({"id": order.id, "customer": order.customer})
    return rows
