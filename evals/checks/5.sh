#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
# Code only: a README or a comment that mentions CSV is not an exporter.
csv=$(git diff "$BASE_REF" --name-only --diff-filter=AM -- 'src/*.ts' 'src/**/*.ts' | sort -u | while IFS= read -r f; do
  added "$f" | grep -Ev '^[[:space:]]*(//|/?\*)' | grep -qi 'csv' && echo "$f"; done | tr '\n' ' ')
[ -n "$csv" ]; check "A CSV exporter is implemented in src/" $? "$csv"
reuse=$(for f in $csv; do grep -lE 'buildSalesReport|ReportRow' "$f"; done | tr '\n' ' ')
[ -n "$reuse" ]; check "Exporter builds on buildSalesReport/ReportRow" $? "$reuse"
git diff --quiet "$BASE_REF" -- package.json; check "No dependency added to package.json" $? "$(git diff "$BASE_REF" -- package.json | grep -E '^\+[^+]' | head -3 | tr '\n' ' ')"
out=$(node_tests); check "Test suite passes" $? "$out"
