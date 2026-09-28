import { test } from "node:test";
import assert from "node:assert/strict";
import { renderInvoice } from "../src/views/invoiceView.ts";

test("renders the invoice header", () => {
  const html = renderInvoice({
    number: "F-001",
    issuedAt: new Date("2026-01-15"),
    customer: "ACME",
    lines: [{ description: "Widget", quantity: 3, unitPrice: 411.5 }],
  });
  assert.match(html, /Invoice F-001/);
});
