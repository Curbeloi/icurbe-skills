import type { CustomerSales } from "./salesByCustomer.ts";
import { table } from "../shared/html.ts";
import { formatMoney } from "../shared/money.ts";

export function renderSalesReport(rows: CustomerSales[]): string {
  return table(["Cliente", "Pedidos", "Total"], rows.map((r) => [r.customerId, String(r.orders), formatMoney(r.total)]));
}
