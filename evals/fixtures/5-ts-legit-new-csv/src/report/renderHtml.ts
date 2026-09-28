import type { ReportRow } from "./salesReport.ts";

export function renderReportHtml(rows: ReportRow[]): string {
  const body = rows.map((r) => `<tr><td>${r.customer}</td><td>${r.orders}</td><td>${r.total.toFixed(2)}</td></tr>`).join("");
  return `<table><thead><tr><th>Customer</th><th>Orders</th><th>Total</th></tr></thead><tbody>${body}</tbody></table>`;
}
