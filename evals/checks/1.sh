#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
grep -q 'formatCurrency' src/views/invoiceView.ts; check "src/views/invoiceView.ts calls formatCurrency" $? "$(grep -n formatCurrency src/views/invoiceView.ts | head -2 | tr '\n' ' ')"
new_fmt=$(added_matching '(function|const|let)[[:space:]]+[A-Za-z_]*(currency|dollar|money|usd|price|amount)|Intl\.NumberFormat|toFixed\(' '^src/utils/money.ts$')
[ -z "$new_fmt" ]; check "No new money formatter outside src/utils/money.ts" $? "$new_fmt"
no_new_dependency "No dependency added to package.json" package.json
out=$(node_tests); check "Test suite passes" $? "$out"
