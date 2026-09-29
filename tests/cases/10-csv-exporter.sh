FIXTURE=10-py-legit-new-csv
CHECK=10
change() {
  cat > app/reports/csv_export.py <<'PY'
import csv
import io

from app.reports.sales import ReportRow


def to_csv(rows: list[ReportRow]) -> str:
    out = io.StringIO()
    writer = csv.writer(out)
    writer.writerow(["customer", "orders", "total"])
    for r in rows:
        writer.writerow([r.customer, r.orders, f"{r.total:.2f}"])
    return out.getvalue()
PY
}
expect() { expect_no_red; expect_checks PPPP; }
