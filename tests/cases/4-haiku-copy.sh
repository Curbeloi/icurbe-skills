# Haiku 4.5's answer to eval 4 with the skill loaded (2026-09-29): the check digit copied with
# $ruc renamed to $cedula, so 4 lines are identical and the rest has the same structure. The
# audit showed only "4 added lines already exist" in YELLOW, the renamed-copy RED was dropped
# because the pair was already reported, and the model justified the YELLOW. One line per
# pair now, coloured by the stronger signal.
FIXTURE=4-php-unify-ruc-cedula
CHECK=4
FINAL_MESSAGE='Implementé la validación de cédula ecuatoriana en el formulario de clientes con un nuevo CedulaValidator.'
change() {
  cat > src/Validation/CedulaValidator.php <<'PHP'
<?php
declare(strict_types=1);

namespace Acme\Crm\Validation;

/** Cédula ecuatoriana de persona natural (Ecuador): 10 dígitos. */
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
        for ($i = 0; $i < 9; $i++) {
            $d = (int) $cedula[$i] * ($i % 2 === 0 ? 2 : 1);
            $suma += $d > 9 ? $d - 9 : $d;
        }
        $verificador = (10 - $suma % 10) % 10;
        return $verificador === (int) $cedula[9];
    }
}
PHP
  perl -pi -e "s|^use Acme\\\\Crm\\\\Validation\\\\RucValidator;|use Acme\\\\Crm\\\\Validation\\\\CedulaValidator;\nuse Acme\\\\Crm\\\\Validation\\\\RucValidator;|;
               s|^        // TODO: tipo 'cedula'|        if (\\\$tipo === 'cedula' && !CedulaValidator::validarCedula(\\\$id)) {\n            \\\$errors['identificacion'] = 'Cédula inválida';\n        }|" src/Customers/CustomerForm.php
}
expect() {
  expect_line '^  \[red\] src/Validation/CedulaValidator.php: .*same structure as code in src/Validation/RucValidator.php'
  expect_checks FFPP
  expect_line 'A RED copy is not a matter of justification'
}
