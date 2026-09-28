import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { queuePaymentReminders } from "../src/payments/reminders.ts";
import { pendingMessages, resetOutbox } from "../src/platform/outbox/outbox.ts";
import { resetOrders } from "../src/orders/orderRepo.ts";

beforeEach(() => { resetOutbox(); resetOrders(); });

test("reminds unpaid orders close to their due date", () => {
  assert.equal(queuePaymentReminders(new Date("2026-10-05")), 1);
  assert.match(pendingMessages()[0].body, /1003/);
});

test("does not remind orders far from their due date", () => {
  assert.equal(queuePaymentReminders(new Date("2026-09-22")), 0);
});
