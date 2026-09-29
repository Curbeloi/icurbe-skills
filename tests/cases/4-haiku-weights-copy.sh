# Another Haiku 4.5 answer to eval 4 (2026-09-29, fixed audit): the check digit with a weights
# array instead of the ternary. 4 identical lines plus a renamed block: each signal alone stayed
# under its RED threshold, the model read the YELLOW as optional and kept the copy. Identical
# lines and renamed structure together are a copy.
FIXTURE=4-php-unify-ruc-cedula
change() {
  cat > src/Validation/CedulaValidator.php <<'PHP'
<?php
declare(strict_types=1);

namespace Acme\Crm\Validation;

/** Cédula de ciudadanía ecuatoriana: 10 dígitos con dígito verificador. */
final class CedulaValidator
{
    public static function validarCedula(string $cedula): bool
    {
        if (!preg_match('/^\d{10}$/', $cedula)) {
            return false;
        }
        $provincia = (int) substr($cedula, 0, 2);
        if ($provincia < 1 || $provincia > 24) {
            return false;
        }
        if ((int) $cedula[2] >= 6) {
            return false;
        }
        $suma = 0;
        $pesos = [2, 1, 2, 1, 2, 1, 2, 1, 2];
        for ($i = 0; $i < 9; $i++) {
            $d = (int) $cedula[$i] * $pesos[$i];
            $suma += $d > 9 ? $d - 9 : $d;
        }
        $verificador = (10 - $suma % 10) % 10;
        return $verificador === (int) $cedula[9];
    }
}
PHP
}
expect() {
  expect_line '^  \[red\] src/Validation/CedulaValidator.php: .*same structure as code in src/Validation/RucValidator.php'
}
