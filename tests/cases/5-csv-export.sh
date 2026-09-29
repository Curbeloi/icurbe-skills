# The right answer to eval 5: a small exporter on ReportRow.
FIXTURE=5-ts-legit-new-csv
CHECK=5
change() {
  cat > src/report/toCsv.ts <<'TS'
import type { ReportRow } from "./salesReport.ts";

const cell = (v: string | number) => (/[",\n]/.test(String(v)) ? `"${String(v).replace(/"/g, '""')}"` : String(v));

export function reportToCsv(rows: ReportRow[]): string {
  return ["customer,orders,total", ...rows.map((r) => [r.customer, r.orders, r.total.toFixed(2)].map(cell).join(","))].join("\n");
}
TS
}
expect() { expect_no_red; expect_quiet_section 6; expect_quiet_section 7; expect_checks PPPP; }
