import type { Customer } from "./customer.ts";
import { escapeHtml } from "../shared/html.ts";

export function renderCustomerCard(c: Customer): string {
  const contact = [c.email, c.phone].filter(Boolean).join(" · ");
  return `<div class="customer"><strong>${escapeHtml(c.name)}</strong><br>${escapeHtml(contact)}</div>`;
}
