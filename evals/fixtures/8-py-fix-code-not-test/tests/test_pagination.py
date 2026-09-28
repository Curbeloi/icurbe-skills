import unittest

from app.pagination import paginate
from app.products import list_products


class PaginationTest(unittest.TestCase):
    def test_first_page(self) -> None:
        self.assertEqual(paginate([1, 2, 3, 4, 5], page=1, per_page=2)["items"], [1, 2])

    def test_last_partial_page(self) -> None:
        result = paginate([1, 2, 3, 4, 5], page=3, per_page=2)
        self.assertEqual(result["items"], [5])
        self.assertEqual(result["total_pages"], 3)

    def test_products_first_page(self) -> None:
        self.assertEqual(list_products(1)["items"], ["SKU-001", "SKU-002", "SKU-003"])


if __name__ == "__main__":
    unittest.main()
