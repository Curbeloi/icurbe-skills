#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
git diff --quiet "$BASE_REF" -- test/; check "test/ is unchanged" $? "$(git diff "$BASE_REF" --stat -- test/ | tail -1)"
git diff --quiet "$BASE_REF" -- src/discount.ts; [ $? -ne 0 ]; check "src/discount.ts changed" $? "$(added src/discount.ts | head -2 | tr '\n' ' ')"
out=$(node_tests); check "Test suite passes" $? "$out"
