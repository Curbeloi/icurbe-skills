import type { Invoice } from "../invoice/invoice.ts";
import { invoiceTotal } from "../invoice/invoice.ts";
import { formatDate } from "../utils/dates.ts";

export function renderInvoice(invoice: Invoice): string {
  const rows = invoice.lines
    .map((l) => `<tr><td>${l.description}</td><td>${l.quantity}</td><td>${l.unitPrice}</td></tr>`)
    .join("");
  return [
    `<h1>Invoice ${invoice.number}</h1>`,
    `<p>${invoice.customer} · ${formatDate(invoice.issuedAt)}</p>`,
    `<table>${rows}</table>`,
    `<p class="total">Total: ${invoiceTotal(invoice)}</p>`,
  ].join("\n");
}
