import { allOrders } from "../orders/orderRepo.ts";
import { orderTotal } from "../orders/orderTotals.ts";
import { paymentDueDate } from "./paymentTerms.ts";
import { daysBetween, formatDate } from "../shared/dates.ts";
import { formatMoney } from "../shared/money.ts";
import { queueMessage } from "../platform/outbox/outbox.ts";

/** Queues a reminder for every unpaid order that is due within `withinDays`. */
export function queuePaymentReminders(today: Date, withinDays = 3): number {
  let queued = 0;
  for (const order of allOrders()) {
    if (order.status !== "new") continue;
    const due = paymentDueDate(order);
    if (daysBetween(today, due) > withinDays) continue;
    queueMessage({
      customerId: order.customerId,
      template: "payment-reminder",
      data: { number: order.number, total: formatMoney(orderTotal(order)), dueDate: formatDate(due) },
    });
    queued++;
  }
  return queued;
}
