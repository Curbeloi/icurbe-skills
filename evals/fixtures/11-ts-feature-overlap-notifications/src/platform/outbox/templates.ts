import { CONFIG } from "../config.ts";

export interface Rendered { subject: string; body: string }
type Template = (data: Record<string, string>) => Rendered;

/** Every customer-facing message, one entry per template name. */
export const TEMPLATES: Record<string, Template> = {
  "payment-reminder": (d) => ({
    subject: `Recordatorio de pago del pedido ${d.number}`,
    body: `Tu pedido ${d.number} por ${d.total} vence el ${d.dueDate}. Gracias por comprar en ${CONFIG.storeName}.`,
  }),
  "order-cancelled": (d) => ({
    subject: `Pedido ${d.number} cancelado`,
    body: `Cancelamos tu pedido ${d.number}. Si no lo pediste tú, responde a este mensaje.`,
  }),
};

export function render(template: string, data: Record<string, string>): Rendered {
  const t = TEMPLATES[template];
  if (!t) throw new Error(`Unknown message template: ${template}`);
  return t(data);
}
