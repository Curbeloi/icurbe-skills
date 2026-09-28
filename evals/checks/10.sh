#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
csv=$(git diff "$BASE_REF" --name-only | grep -v '^tests/' | grep '\.py$' | xargs grep -il 'csv' 2>/dev/null | tr '\n' ' ')
[ -n "$csv" ]; check "A CSV exporter is implemented" $? "$csv"
reuse=$(for f in $csv; do grep -lE 'build_sales_report|ReportRow' "$f"; done | tr '\n' ' ')
[ -n "$reuse" ]; check "Exporter builds on build_sales_report/ReportRow" $? "$reuse"
deps=$( (added requirements.txt pyproject.toml setup.py setup.cfg 2>/dev/null; added app | grep -E '^(import|from) (pandas|polars|numpy)') | grep -Ei '[a-z]')
[ -z "$deps" ]; check "No dependency added (no pandas)" $? "$deps"
out=$(py_tests); check "Test suite passes" $? "$out"
