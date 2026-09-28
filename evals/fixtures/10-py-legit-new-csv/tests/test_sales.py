import unittest

from app.reports.sales import ReportRow, Sale, build_sales_report


class SalesReportTest(unittest.TestCase):
    def test_groups_by_customer(self) -> None:
        rows = build_sales_report([
            Sale("2026-01-01", "Ana", "A", 10.0),
            Sale("2026-01-02", "Ana", "B", 5.0),
            Sale("2026-01-02", "Luis", "A", 30.0),
        ])
        self.assertEqual(rows, [ReportRow("Luis", 1, 30.0), ReportRow("Ana", 2, 15.0)])


if __name__ == "__main__":
    unittest.main()
