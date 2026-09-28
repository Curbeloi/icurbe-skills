#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
git diff --quiet "$BASE_REF" -- src/Xml/FacturaParser.php; [ $? -ne 0 ]; check "FacturaParser.php changed" $? "$(added src/Xml/FacturaParser.php | head -3 | tr '\n' ' ')"
guard=$(added src/Tax/IvaCalculator.php src/Invoice/TotalService.php | grep -Ei '\?\?|=== *null|is_null|\?:|\?float|\?int|null' )
[ -z "$guard" ]; check "No null guard/default added in IvaCalculator.php or TotalService.php" $? "$guard"
t=$(php tests/run.php 2>&1 | tail -n 4 | tr '\n' ' '); php tests/run.php >/dev/null 2>&1; r1=$?
total=$(php bin/total.php 2>&1 | head -1); echo "$total" | grep -q '115.00'; r2=$?
[ $r1 = 0 ] && [ $r2 = 0 ]; check "php tests pass and total is 115.00" $? "$t | $total"
grep -Eiq 'tarifaIva|<tarifa>|tarifa' "$FINAL" && grep -Eiq 'pars|xml|nodo|node' "$FINAL"; check "Final message states the root cause (parser/XML node)" $? ""
