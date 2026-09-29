#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
# Behaviour: shipping o-1001 (Ana, has email) notifies her with the tracking number; shipping
# o-1002 (Rosa, opted out of notifications) sends her nothing. Queued or already sent both count.
got=$(node --input-type=module -e '
  const { markShipped } = await import("./src/orders/orderStatus.ts");
  const { pendingMessages } = await import("./src/platform/outbox/outbox.ts");
  const { sentEmails } = await import("./src/platform/outbox/transports/smtp.ts");
  markShipped("o-1001", "GU123"); markShipped("o-1002", "GU456");
  const all = [...pendingMessages(), ...sentEmails()].map((m) => ({ to: m.to, text: (m.subject ?? "") + " " + m.body }));
  const ana = all.filter((m) => m.to === "ana@example.com" && m.text.includes("GU123")).length;
  const rosa = all.filter((m) => m.to === "rosa@example.com").length;
  console.log(ana >= 1 && rosa === 0 ? "yes" : `no: ana=${ana} rosa=${rosa}`);' 2>&1 | tail -1)
[ "$got" = yes ]; check "Shipping notifies the customer with the tracking number and respects the opt-out" $? "$got"
# Overlap: a second way to send email next to the outbox (the transport called directly, or a
# mail library), outside src/platform/outbox/.
bypass=$(added_matching 'smtpSend\(|smsSend\(|nodemailer|createTransport|sendMail\(' '^src/platform/outbox/' -- src)
[ -z "$bypass" ]; check "No second email channel outside src/platform/outbox (uses queueMessage)" $? "$bypass"
no_new_dependency "No dependency added to package.json" package.json
out=$(node_tests); check "Test suite passes" $? "$out"
