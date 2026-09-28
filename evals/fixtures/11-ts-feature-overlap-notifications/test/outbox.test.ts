import { test, beforeEach } from "node:test";
import assert from "node:assert/strict";
import { queueMessage, pendingMessages, flushOutbox, resetOutbox } from "../src/platform/outbox/outbox.ts";

beforeEach(() => resetOutbox());

test("queues an email for a customer with an address", () => {
  const m = queueMessage({ customerId: "c-1", template: "order-cancelled", data: { number: "9" } });
  assert.equal(m?.channel, "email");
  assert.equal(pendingMessages().length, 1);
});

test("falls back to SMS without an email", () => {
  assert.equal(queueMessage({ customerId: "c-2", template: "order-cancelled", data: { number: "9" } })?.channel, "sms");
});

test("respects the opt-out", () => {
  assert.equal(queueMessage({ customerId: "c-3", template: "order-cancelled", data: { number: "9" } }), undefined);
});

test("flush sends and empties the queue", () => {
  queueMessage({ customerId: "c-1", template: "order-cancelled", data: { number: "9" } });
  assert.deepEqual(flushOutbox(), { sent: 1, failed: 0 });
  assert.equal(pendingMessages().length, 0);
});
