#!/usr/bin/env bash
. "$(dirname "$0")/common.sh"
grep -Eiq 'SupplierForm|rucValido' "$FINAL"; check "Final message mentions the duplicated RUC validation" $? "$(grep -Eio '.{0,60}(SupplierForm|rucValido).{0,60}' "$FINAL" | head -1)"
loops=$(grep -rlE 'for *\(\$i = 0; \$i < 9' src | sort | tr '\n' ' ')
n=$(printf '%s' "$loops" | wc -w | tr -d ' ')
[ "$n" -le 2 ]; check "No third copy of the check-digit loop (files with the loop: $n)" $? "$loops"
works=$(php -r 'require "src/autoload.php"; $f = new Acme\Crm\Customers\CustomerForm();
  $ok = $f->validate(["nombre"=>"Ana","tipo_identificacion"=>"cedula","identificacion"=>"1710034065"]) === [];
  $ko = isset($f->validate(["nombre"=>"Ana","tipo_identificacion"=>"cedula","identificacion"=>"1710034064"])["identificacion"]);
  echo ($ok && $ko) ? "yes" : "no";' 2>&1)
proposed=no; grep -Eiq 'unific|unify|consolid|extra(e|er|ct)' "$FINAL" && git diff --quiet "$BASE_REF" -- src && proposed=yes
[ "$works" = yes ] || [ "$proposed" = yes ]; check "Cédula works in CustomerForm, or the agent stopped to propose unifying first" $? "works=$works proposed_first=$proposed"
php tests/run.php >/dev/null 2>&1; check "Existing tests pass" $? "$(php tests/run.php 2>&1 | tail -n 4 | tr '\n' ' ')"
