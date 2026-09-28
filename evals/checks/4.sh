#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
grep -Eiq 'SupplierForm|rucValido' "$FINAL"; check "Final message mentions the duplicated RUC validation" $? "$(grep -Eio '.{0,60}(SupplierForm|rucValido).{0,60}' "$FINAL" | head -1)"
# Files that implement the modulo-10 check digit, however it is written: a "% 10" check plus
# alternating 2/1 weights ("% 2", or a coefficients array such as [2, 1, 2, ...]).
algo=$(grep -rlE '%[[:space:]]*10' src --include='*.php' 2>/dev/null \
  | while IFS= read -r f; do grep -qE '%[[:space:]]*2([^0-9]|$)|2,[[:space:]]*1,[[:space:]]*2' "$f" && echo "$f"; done | sort | tr '\n' ' ')
n=$(printf '%s' "$algo" | wc -w | tr -d ' ')
audit=$(NO_COLOR=1 bash "$(dirname "$0")/../../skills/reuse-before-write/scripts/audit-diff.sh" "$BASE_REF" 2>/dev/null | grep -E 'same structure as|already exist in' | sed 's/^ *//' | head -2 | tr '\n' ' ')
[ "$n" -le 2 ]; check "No third copy of the check-digit algorithm (files with it: $n)" $? "$algo${audit:+| audit: $audit}"
works=$(php -r 'require "src/autoload.php"; $f = new Acme\Crm\Customers\CustomerForm();
  $ok = $f->validate(["nombre"=>"Ana","tipo_identificacion"=>"cedula","identificacion"=>"1710034065"]) === [];
  $ko = isset($f->validate(["nombre"=>"Ana","tipo_identificacion"=>"cedula","identificacion"=>"1710034064"])["identificacion"]);
  echo ($ok && $ko) ? "yes" : "no";' 2>&1)
proposed=no; grep -Eiq 'unific|unify|consolid|extra(e|er|ct)' "$FINAL" && git diff --quiet "$BASE_REF" -- src && proposed=yes
[ "$works" = yes ] || [ "$proposed" = yes ]; check "Cédula works in CustomerForm, or the agent stopped to propose unifying first" $? "works=$works proposed_first=$proposed"
php tests/run.php >/dev/null 2>&1; check "Existing tests pass" $? "$(php tests/run.php 2>&1 | tail -n 4 | tr '\n' ' ')"
