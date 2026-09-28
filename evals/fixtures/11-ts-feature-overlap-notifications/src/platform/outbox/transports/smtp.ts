export interface SentEmail { from: string; to: string; subject: string; body: string }

const sent: SentEmail[] = [];

/** Low-level email transport. Use queueMessage() in outbox.ts; this does no opt-out or retry. */
export function smtpSend(from: string, to: string, subject: string, body: string): boolean {
  if (!to.includes("@")) return false;
  sent.push({ from, to, subject, body });
  return true;
}

export function sentEmails(): readonly SentEmail[] {
  return sent;
}
