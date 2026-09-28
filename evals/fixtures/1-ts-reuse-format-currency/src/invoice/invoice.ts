import { roundCents } from "../utils/money.ts";

export interface InvoiceLine {
  description: string;
  quantity: number;
  unitPrice: number;
}

export interface Invoice {
  number: string;
  issuedAt: Date;
  customer: string;
  lines: InvoiceLine[];
}

export function invoiceTotal(invoice: Invoice): number {
  return roundCents(invoice.lines.reduce((sum, l) => sum + l.quantity * l.unitPrice, 0));
}
