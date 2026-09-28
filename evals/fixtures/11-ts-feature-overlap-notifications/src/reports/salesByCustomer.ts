import { allOrders } from "../orders/orderRepo.ts";
import { orderTotal } from "../orders/orderTotals.ts";

export interface CustomerSales { customerId: string; orders: number; total: number }

export function salesByCustomer(): CustomerSales[] {
  const acc = new Map<string, CustomerSales>();
  for (const o of allOrders()) {
    if (o.status === "cancelled" || o.status === "new") continue;
    const row = acc.get(o.customerId) ?? { customerId: o.customerId, orders: 0, total: 0 };
    row.orders += 1;
    row.total += orderTotal(o);
    acc.set(o.customerId, row);
  }
  return [...acc.values()].sort((a, b) => b.total - a.total);
}
