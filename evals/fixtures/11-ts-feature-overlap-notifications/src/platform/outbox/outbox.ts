import { findCustomer } from "../../customers/customerRepo.ts";
import { CONFIG } from "../config.ts";
import { nextId } from "../../shared/ids.ts";
import { render } from "./templates.ts";
import { smtpSend } from "./transports/smtp.ts";
import { smsSend } from "./transports/sms.ts";

export type Channel = "email" | "sms";

export interface OutboxMessage {
  id: string;
  channel: Channel;
  to: string;
  subject: string;
  body: string;
  attempts: number;
}

export interface MessageRequest {
  customerId: string;
  template: string;
  data: Record<string, string>;
  /** Defaults to email when the customer has one, SMS otherwise. */
  channel?: Channel;
}

const pending: OutboxMessage[] = [];

/**
 * Queues a customer notification. Respects the customer's opt-out, picks the channel from the
 * contact data, renders the template. Returns undefined when nothing was queued.
 */
export function queueMessage(req: MessageRequest): OutboxMessage | undefined {
  const customer = findCustomer(req.customerId);
  if (!customer || customer.notificationsOptOut) return undefined;
  const channel = req.channel ?? (customer.email ? "email" : "sms");
  const to = channel === "email" ? customer.email : customer.phone;
  if (!to) return undefined;
  const { subject, body } = render(req.template, req.data);
  const msg = { id: nextId("msg"), channel, to, subject, body, attempts: 0 };
  pending.push(msg);
  return msg;
}

/** Sends what is pending; failed messages stay queued until outboxMaxAttempts. */
export function flushOutbox(): { sent: number; failed: number } {
  let sent = 0;
  let failed = 0;
  for (const msg of [...pending]) {
    msg.attempts++;
    const ok = msg.channel === "email"
      ? smtpSend(CONFIG.senderEmail, msg.to, msg.subject, msg.body)
      : smsSend(CONFIG.senderSms, msg.to, msg.body);
    if (ok || msg.attempts >= CONFIG.outboxMaxAttempts) pending.splice(pending.indexOf(msg), 1);
    if (ok) sent++;
    else failed++;
  }
  return { sent, failed };
}

export function pendingMessages(): readonly OutboxMessage[] {
  return pending;
}

/** Test helper. */
export function resetOutbox(): void {
  pending.length = 0;
}
