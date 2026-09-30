# The same check digit with a foreach instead of a for, squeezed on fewer lines: the loop body
# still has the same structure.
FIXTURE=4-php-unify-ruc-cedula
change() {
  cat > src/Validation/CedulaValidator.php <<'PHP'
<?php
namespace Acme\Crm\Validation;
final class CedulaValidator {
    public static function validarCedula(string $c): bool {
        if (!preg_match('/^\d{10}$/', $c)) { return false; }
        $suma = 0;
        foreach (range(0, 8) as $i) { $d = (int) $c[$i] * ($i % 2 === 0 ? 2 : 1); $suma += $d > 9 ? $d - 9 : $d; }
        return (10 - $suma % 10) % 10 === (int) $c[9];
    }
}
PHP
}
expect() {
  expect_no_line 'A RED copy is not a matter of justification'   # YELLOW: one signal under its threshold
  expect_line '^  \[(yellow|red)\] src/Validation/CedulaValidator.php: .*same structure as code in src/Validation/RucValidator.php'
}
