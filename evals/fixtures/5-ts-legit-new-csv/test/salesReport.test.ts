import { test } from "node:test";
import assert from "node:assert/strict";
import { buildSalesReport } from "../src/report/salesReport.ts";

test("groups by customer", () => {
  const rows = buildSalesReport([
    { date: "2026-01-01", customer: "Ana", product: "A", amount: 10 },
    { date: "2026-01-02", customer: "Ana", product: "B", amount: 5 },
    { date: "2026-01-02", customer: "Luis", product: "A", amount: 30 },
  ]);
  assert.deepEqual(rows, [
    { customer: "Luis", orders: 1, total: 30 },
    { customer: "Ana", orders: 2, total: 15 },
  ]);
});
