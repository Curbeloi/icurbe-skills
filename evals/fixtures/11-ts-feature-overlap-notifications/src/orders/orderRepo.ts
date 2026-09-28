import type { Order } from "./order.ts";

const orders = new Map<string, Order>();

function seed(): void {
  orders.clear();
  orders.set("o-1001", { id: "o-1001", number: "1001", customerId: "c-1", createdAt: new Date("2026-09-20"), status: "paid", lines: [{ sku: "CAF-1K", quantity: 2, unitPrice: 22 }] });
  orders.set("o-1002", { id: "o-1002", number: "1002", customerId: "c-3", createdAt: new Date("2026-09-21"), status: "paid", lines: [{ sku: "TAZ-01", quantity: 4, unitPrice: 9.9 }] });
  orders.set("o-1003", { id: "o-1003", number: "1003", customerId: "c-2", createdAt: new Date("2026-09-22"), status: "new", lines: [{ sku: "CAF-250", quantity: 10, unitPrice: 6.18 }] });
}
seed();

export function findOrder(id: string): Order | undefined {
  return orders.get(id);
}

export function saveOrder(order: Order): void {
  orders.set(order.id, order);
}

export function allOrders(): Order[] {
  return [...orders.values()];
}

/** Test helper: restore the seed data. */
export function resetOrders(): void {
  seed();
}
