import type { Order } from "./order.ts";
import { orderTotal } from "./orderTotals.ts";
import { findCustomer } from "../customers/customerRepo.ts";
import { formatDate } from "../shared/dates.ts";
import { formatMoney } from "../shared/money.ts";
import { escapeHtml, table } from "../shared/html.ts";

export function renderOrderDetail(order: Order): string {
  const customer = findCustomer(order.customerId);
  const rows = order.lines.map((l) => [l.sku, String(l.quantity), formatMoney(l.unitPrice)]);
  return [
    `<h1>Pedido ${escapeHtml(order.number)}</h1>`,
    `<p>${escapeHtml(customer?.name ?? order.customerId)} · ${formatDate(order.createdAt)} · ${order.status}</p>`,
    table(["SKU", "Cantidad", "Precio"], rows),
    `<p class="total">Total: ${formatMoney(orderTotal(order))}</p>`,
  ].join("\n");
}
