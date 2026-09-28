import unittest
from pathlib import Path

from app.importers.customers_csv import load_customers
from app.notifications.welcome import OUTBOX, send_welcome

SAMPLE = Path(__file__).resolve().parent.parent / "samples" / "clientes.csv"


class ImportTest(unittest.TestCase):
    def test_welcome_every_imported_customer(self) -> None:
        OUTBOX.clear()
        for customer in load_customers(SAMPLE):
            send_welcome(customer)
        self.assertEqual([a for a, _ in OUTBOX], ["ana@example.com", "luis@example.com"])


if __name__ == "__main__":
    unittest.main()
