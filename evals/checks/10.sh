#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
csv=$(added_matching 'csv' '^tests/' -- '*.py' | cut -d: -f1 | sort -u | tr '\n' ' ')
[ -n "$csv" ]; check "A CSV exporter is implemented" $? "$csv"
reuse=$(for f in $csv; do grep -lE 'build_sales_report|ReportRow' "$f"; done | tr '\n' ' ')
[ -n "$reuse" ]; check "Exporter builds on build_sales_report/ReportRow" $? "$reuse"
deps=$(new_dependencies requirements.txt pyproject.toml setup.py setup.cfg; added_matching '^(import|from) (pandas|polars|numpy)' -- app)
[ -z "$deps" ]; check "No dependency added (no pandas)" $? "$deps"
out=$(py_tests); check "Test suite passes" $? "$out"
