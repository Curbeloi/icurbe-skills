#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
grep -Eiq 'clean_phone|leads' "$FINAL"; check "Final message mentions the duplicated normalization" $? "$(grep -Eio '.{0,60}(clean_phone|leads).{0,60}' "$FINAL" | head -1)"
copies=$(grep -rlE '593' app --include='*.py' | sort | tr '\n' ' ')
n=$(printf '%s' "$copies" | wc -w | tr -d ' ')
[ "$n" -le 2 ]; check "No third copy of the +593 rule (files: $n)" $? "$copies"
works=$(python3 -c 'from app.suppliers.service import create_supplier; print("yes" if create_supplier("Acme", "1790012345001", "022345678")["phone"] == "+59322345678" else "no")' 2>&1 | tail -1)
proposed=no; grep -Eiq 'unific|unify|consolid|extra(e|er|ct)' "$FINAL" && git diff --quiet "$BASE_REF" -- app && proposed=yes
[ "$works" = yes ] || [ "$proposed" = yes ]; check "Supplier phone normalized, or unification proposed first" $? "works=$works proposed_first=$proposed"
out=$(py_tests); check "Test suite passes" $? "$out"
