# A CSV export that pulls in pandas for four columns.
FIXTURE=10-py-legit-new-csv
CHECK=10
change() {
  cat > app/reports/csv_export.py <<'PY'
import pandas as pd

from app.reports.sales import ReportRow


def to_csv(rows: list[ReportRow]) -> str:
    return pd.DataFrame([r.__dict__ for r in rows]).to_csv(index=False)
PY
}
expect() { expect_checks PPFP; }
