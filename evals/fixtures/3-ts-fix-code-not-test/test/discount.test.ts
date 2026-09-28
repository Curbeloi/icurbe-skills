import { test } from "node:test";
import assert from "node:assert/strict";
import { applyDiscount } from "../src/discount.ts";
import { cartTotal } from "../src/cart.ts";

test("10% off 100 is 90", () => {
  assert.equal(applyDiscount(100, 0.1), 90);
});

test("no discount keeps the price", () => {
  assert.equal(applyDiscount(59.99, 0), 59.99);
});

test("cart applies the coupon to the gross total", () => {
  assert.equal(cartTotal([{ sku: "A", price: 20, qty: 5 }], 0.25), 75);
});
