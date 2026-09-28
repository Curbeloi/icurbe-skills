export interface AuditEvent { at: Date; type: string; data: Record<string, unknown> }

const events: AuditEvent[] = [];

export function recordEvent(type: string, data: Record<string, unknown>): void {
  events.push({ at: new Date(), type, data });
}

export function auditEvents(): readonly AuditEvent[] {
  return events;
}
