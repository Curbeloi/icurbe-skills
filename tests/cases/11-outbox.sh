# The right answer to eval 11: a template and queueMessage, through the outbox.
FIXTURE=11-ts-feature-overlap-notifications
CHECK=11
SEARCH=(send email notification)
change() {
  perl -0pi -e 's|(  "order-cancelled": \(d\) => \(\{)|  "order-shipped": (d) => ({\n    subject: `Tu pedido \${d.number} va en camino`,\n    body: `Despachamos tu pedido \${d.number}. Número de guía: \${d.trackingNumber}.`,\n  }),\n$1|' \
    src/platform/outbox/templates.ts
  perl -0pi -e 's|(import \{ recordEvent \} from "../platform/audit/auditLog.ts";)|$1\nimport { queueMessage } from "../platform/outbox/outbox.ts";|;
                s|(  saveOrder\(withTracking\);\n)|$1  queueMessage({ customerId: order.customerId, template: "order-shipped", data: { number: order.number, trackingNumber } });\n|' \
    src/orders/orderStatus.ts
}
expect() {
  expect_summary GREEN
  expect_checks PPPP
  expect_found 'src/platform/outbox/'   # the searches an agent would run lead to the outbox
}
