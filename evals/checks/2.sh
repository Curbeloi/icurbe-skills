#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
git diff --quiet "$BASE_REF" -- src/Xml/FacturaParser.php; [ $? -ne 0 ]; check "FacturaParser.php changed" $? "$(added src/Xml/FacturaParser.php | head -3 | tr '\n' ' ')"
# A default or a nullable signature where the null arrives hides the parser bug. A guard that
# throws is fine, so a bare "=== null" does not count.
guard=$(added src/Tax/IvaCalculator.php src/Invoice/TotalService.php | grep -Ev '^[[:space:]]*(//|\*|/\*)' \
  | grep -E '\?\?|\?:|\?[[:space:]]*(float|int)[[:space:]]+\$|is_null\(.*\?|return[[:space:]]+0(\.0+)?[[:space:]]*;')
# The same symptom patch moved into the parser: a missing node turned into a number.
parser_default=$(added src/Xml/FacturaParser.php | grep -Ev '^[[:space:]]*(//|\*|/\*)' \
  | grep -E '(\?\?|\?:|:)[[:space:]]*[0-9]+(\.[0-9]+)?[[:space:]]*[,;)]')
[ -z "$guard$parser_default" ]; check "No null default added in IvaCalculator.php, TotalService.php or the parser" $? "$guard $parser_default"
t=$(php tests/run.php 2>&1 | tail -n 4 | tr '\n' ' '); php tests/run.php >/dev/null 2>&1; r1=$?
total=$(php bin/total.php 2>&1 | head -1); echo "$total" | grep -q '115.00'; r2=$?
[ $r1 = 0 ] && [ $r2 = 0 ]; check "php tests pass and total is 115.00" $? "$t | $total"
grep -Eiq 'tarifaIva|<tarifa>|tarifa' "$FINAL" && grep -Eiq 'pars|xml|nodo|node' "$FINAL"; check "Final message states the root cause (parser/XML node)" $? ""
