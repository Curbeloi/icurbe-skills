import type { Order, OrderStatus } from "./order.ts";
import { findOrder, saveOrder } from "./orderRepo.ts";
import { recordEvent } from "../platform/audit/auditLog.ts";

const ALLOWED: Record<OrderStatus, OrderStatus[]> = {
  new: ["paid", "cancelled"],
  paid: ["shipped", "cancelled"],
  shipped: ["delivered"],
  delivered: [],
  cancelled: [],
};

function transition(orderId: string, to: OrderStatus): Order {
  const order = findOrder(orderId);
  if (!order) throw new Error(`Order ${orderId} not found`);
  if (!ALLOWED[order.status].includes(to)) {
    throw new Error(`Order ${order.number} cannot go from ${order.status} to ${to}`);
  }
  const updated = { ...order, status: to };
  saveOrder(updated);
  recordEvent("order.status", { orderId, from: order.status, to });
  return updated;
}

export function markPaid(orderId: string): Order {
  return transition(orderId, "paid");
}

export function markShipped(orderId: string, trackingNumber: string): Order {
  const order = transition(orderId, "shipped");
  const withTracking = { ...order, trackingNumber };
  saveOrder(withTracking);
  return withTracking;
}

export function markDelivered(orderId: string): Order {
  return transition(orderId, "delivered");
}

export function cancelOrder(orderId: string): Order {
  return transition(orderId, "cancelled");
}
