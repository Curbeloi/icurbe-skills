#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
csv=$(git diff "$BASE_REF" --name-only | grep -v '^test/' | xargs grep -il 'csv' 2>/dev/null | tr '\n' ' ')
[ -n "$csv" ]; check "A CSV exporter is implemented" $? "$csv"
reuse=$(for f in $csv; do grep -lE 'buildSalesReport|ReportRow' "$f"; done | tr '\n' ' ')
[ -n "$reuse" ]; check "Exporter builds on buildSalesReport/ReportRow" $? "$reuse"
git diff --quiet "$BASE_REF" -- package.json; check "No dependency added to package.json" $? "$(git diff "$BASE_REF" -- package.json | grep -E '^\+[^+]' | head -3 | tr '\n' ' ')"
out=$(node_tests); check "Test suite passes" $? "$out"
