import type { Order } from "./order.ts";
import { roundCents } from "../shared/money.ts";

export function orderTotal(order: Order): number {
  return roundCents(order.lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0));
}
