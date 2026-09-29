# A CSV exporter that adds a library to package.json for something a few lines do.
FIXTURE=5-ts-legit-new-csv
CHECK=5
change() {
  perl -pi -e 's/"dependencies": \{\}/"dependencies": { "papaparse": "^5.4.1" }/' package.json
  cat > src/report/toCsv.ts <<'TS'
import Papa from "papaparse";
import type { ReportRow } from "./salesReport.ts";

export const reportToCsv = (rows: ReportRow[]): string => Papa.unparse(rows);
TS
}
expect() { expect_line '^  \[yellow\] package.json changed'; expect_checks PPFP; }
