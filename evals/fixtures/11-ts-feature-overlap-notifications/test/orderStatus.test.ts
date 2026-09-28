import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { markShipped, cancelOrder } from "../src/orders/orderStatus.ts";
import { findOrder, resetOrders } from "../src/orders/orderRepo.ts";

beforeEach(() => resetOrders());

test("a paid order can be shipped with a tracking number", () => {
  const o = markShipped("o-1001", "GU-1");
  assert.equal(o.status, "shipped");
  assert.equal(findOrder("o-1001")?.trackingNumber, "GU-1");
});

test("a new order cannot be shipped", () => {
  assert.throws(() => markShipped("o-1003", "GU-2"), /cannot go from new to shipped/);
});

test("a paid order can be cancelled", () => {
  assert.equal(cancelOrder("o-1002").status, "cancelled");
});
