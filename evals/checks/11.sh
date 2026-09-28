#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
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
bypass=$(git diff "$BASE_REF" --name-only -- src | grep -v '^src/platform/outbox/' | while IFS= read -r f; do
  added "$f" | grep -Ev '^[[:space:]]*(//|/?\*)' | grep -E 'smtpSend\(|smsSend\(|nodemailer|createTransport|sendMail\(' | sed "s|^|$f: |"; done)
[ -z "$bypass" ]; check "No second email channel outside src/platform/outbox (uses queueMessage)" $? "$bypass"
git diff --quiet "$BASE_REF" -- package.json; check "No dependency added to package.json" $? "$(git diff "$BASE_REF" -- package.json | grep -E '^\+[^+]' | head -3 | tr '\n' ' ')"
out=$(node_tests); check "Test suite passes" $? "$out"
