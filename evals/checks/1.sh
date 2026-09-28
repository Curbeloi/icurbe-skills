#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
grep -q 'formatCurrency' src/views/invoiceView.ts; check "src/views/invoiceView.ts calls formatCurrency" $? "$(grep -n formatCurrency src/views/invoiceView.ts | head -2 | tr '\n' ' ')"
new_fmt=$(git add -A -N . && git diff "$BASE_REF" --name-only | grep -v '^src/utils/money.ts$' | while read -r f; do
  [ -f "$f" ] && git diff "$BASE_REF" -U0 -- "$f" | grep -E '^\+[^+]' | grep -Ei '(function|const|let)[[:space:]]+[A-Za-z_]*(currency|dollar|money|usd|price|amount)|Intl\.NumberFormat|toFixed\(' | sed "s|^|$f: |"; done)
[ -z "$new_fmt" ]; check "No new money formatter outside src/utils/money.ts" $? "$new_fmt"
git diff --quiet "$BASE_REF" -- package.json; check "No dependency added to package.json" $? "$(git diff "$BASE_REF" -- package.json | grep -E '^\+[^+]' | head -3 | tr '\n' ' ')"
out=$(node_tests); check "Test suite passes" $? "$out"
