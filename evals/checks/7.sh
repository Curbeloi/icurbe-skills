#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
grep -Eq 'utf-8-sig|utf_8_sig|\\ufeff|BOM_UTF8' app/importers/customers_csv.py; check "The importer handles the BOM" $? "$(added app/importers/customers_csv.py | head -3 | tr '\n' ' ')"
guard=$(added app/notifications/welcome.py | grep -E 'if not|is None|is not None|or ""|or '"''"'|try:|except|getattr|\.get\(')
[ -z "$guard" ]; check "No None guard/default/try in welcome.py" $? "$guard"
out=$(py_tests); r1=$?; cli=$(python3 -m app.cli 2>&1 | tail -1); echo "$cli" | grep -q '^2 bienvenidas'; r2=$?
[ $r1 = 0 ] && [ $r2 = 0 ]; check "Tests pass and the CLI sends 2 welcomes" $? "$out | $cli"
grep -Eiq 'bom|utf-8-sig|byte order|ufeff' "$FINAL"; check "Final message states the root cause (BOM)" $? ""
