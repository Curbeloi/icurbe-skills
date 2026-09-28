import unittest
from datetime import date

from app.orders.models import Order
from app.orders.report import late_orders


class LateOrdersTest(unittest.TestCase):
    def test_only_late_orders(self) -> None:
        orders = [
            Order("A1", "Ana", date(2026, 3, 2), date(2026, 3, 9)),
            Order("A2", "Luis", date(2026, 3, 2), date(2026, 3, 2)),
            Order("A3", "Eva", date(2026, 3, 2)),
        ]
        self.assertEqual([r["id"] for r in late_orders(orders)], ["A1"])


if __name__ == "__main__":
    unittest.main()
