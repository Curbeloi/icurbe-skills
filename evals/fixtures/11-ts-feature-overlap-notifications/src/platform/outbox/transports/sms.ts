export interface SentSms { from: string; to: string; body: string }

const sent: SentSms[] = [];

/** Low-level SMS transport. Use queueMessage() in outbox.ts; this does no opt-out or retry. */
export function smsSend(from: string, to: string, body: string): boolean {
  if (!/^\+\d{8,15}$/.test(to)) return false;
  sent.push({ from, to, body: body.slice(0, 160) });
  return true;
}

export function sentSms(): readonly SentSms[] {
  return sent;
}
