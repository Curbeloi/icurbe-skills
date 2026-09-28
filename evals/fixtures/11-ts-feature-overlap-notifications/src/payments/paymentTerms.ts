import type { Order } from "../orders/order.ts";
import { addDays } from "../shared/dates.ts";

export const PAYMENT_TERM_DAYS = 15;

export function paymentDueDate(order: Order): Date {
  return addDays(order.createdAt, PAYMENT_TERM_DAYS);
}
