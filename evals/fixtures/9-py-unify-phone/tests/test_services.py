import unittest

from app.customers.service import create_customer
from app.leads.service import create_lead
from app.suppliers.service import create_supplier


class ServicesTest(unittest.TestCase):
    def test_customer_phone(self) -> None:
        self.assertEqual(create_customer("Ana", "099 123 4567")["phone"], "+593991234567")

    def test_lead_phone(self) -> None:
        self.assertEqual(create_lead("Luis", "+593 (99) 765-4321")["phone"], "+593997654321")

    def test_supplier_created(self) -> None:
        self.assertEqual(create_supplier(" Acme ", "1790012345001", "022345678")["company"], "Acme")


if __name__ == "__main__":
    unittest.main()
