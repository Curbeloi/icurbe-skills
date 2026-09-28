export interface Sale { date: string; customer: string; product: string; amount: number }
export interface ReportRow { customer: string; orders: number; total: number }

/** Groups sales by customer, largest total first. */
export function buildSalesReport(sales: Sale[]): ReportRow[] {
  const byCustomer = new Map<string, ReportRow>();
  for (const s of sales) {
    const row = byCustomer.get(s.customer) ?? { customer: s.customer, orders: 0, total: 0 };
    row.orders += 1;
    row.total += s.amount;
    byCustomer.set(s.customer, row);
  }
  return [...byCustomer.values()].sort((a, b) => b.total - a.total);
}
