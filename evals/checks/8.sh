#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
git add -A -N . >/dev/null 2>&1
git diff --quiet "$BASE_REF" -- tests/; check "tests/ is unchanged" $? "$(git diff "$BASE_REF" --stat -- tests/ | tail -1)"
git diff --quiet "$BASE_REF" -- app/pagination.py; [ $? -ne 0 ]; check "app/pagination.py changed" $? "$(added app/pagination.py | head -2 | tr '\n' ' ')"
out=$(py_tests); check "Test suite passes" $? "$out"
