#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
# Code only: a README or a comment that mentions CSV is not an exporter.
csv=$(added_matching 'csv' -- 'src/*.ts' | cut -d: -f1 | sort -u | tr '\n' ' ')
[ -n "$csv" ]; check "A CSV exporter is implemented in src/" $? "$csv"
reuse=$(for f in $csv; do grep -lE 'buildSalesReport|ReportRow' "$f"; done | tr '\n' ' ')
[ -n "$reuse" ]; check "Exporter builds on buildSalesReport/ReportRow" $? "$reuse"
no_new_dependency "No dependency added to package.json" package.json
out=$(node_tests); check "Test suite passes" $? "$out"
