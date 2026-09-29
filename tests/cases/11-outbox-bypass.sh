# New code that calls the SMTP transport directly, around the outbox that owns it (and handles
# the opt-out): a second way into an existing feature.
FIXTURE=11-ts-feature-overlap-notifications
CHECK=11
change() {
  cat > src/orders/shippingEmail.ts <<'TS'
import type { Order } from "./order.ts";
import { findCustomer } from "../customers/customerRepo.ts";
import { smtpSend } from "../platform/outbox/transports/smtp.ts";
import { CONFIG } from "../platform/config.ts";

export function sendShippingEmail(order: Order, trackingNumber: string): boolean {
  const customer = findCustomer(order.customerId);
  if (!customer?.email) return false;
  return smtpSend(CONFIG.senderEmail, customer.email, `Pedido ${order.number} despachado`, `Guía: ${trackingNumber}`);
}
TS
  perl -0pi -e 's|(import \{ recordEvent \} from "../platform/audit/auditLog.ts";)|$1\nimport { sendShippingEmail } from "./shippingEmail.ts";|;
                s|(  saveOrder\(withTracking\);\n)|$1  sendShippingEmail(withTracking, trackingNumber);\n|' src/orders/orderStatus.ts
}
expect() {
  expect_line '^  \[yellow\] sendShippingEmail .* calls smtpSend, which until now only src/platform/outbox/ used'
  expect_checks FFPP   # the opted-out customer gets the email too
}
