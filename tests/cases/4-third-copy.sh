# Haiku's answer to eval 4: a new validator that re-implements the check digit, wired in.
FIXTURE=4-php-unify-ruc-cedula
CHECK=4
FINAL_MESSAGE='Agregué CedulaValidator siguiendo el mismo patrón que RucValidator; SupplierForm tiene su propia copia.'
change() {
  cat > src/Validation/CedulaValidator.php <<'PHP'
<?php
declare(strict_types=1);

namespace Acme\Crm\Validation;

/** Cédula ecuatoriana: 10 dígitos, provincia 01-24, tercer dígito < 6, dígito verificador módulo 10. */
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
        $total = 0;
        for ($i = 0; $i < 9; $i++) {
            $valor = (int) $cedula[$i] * ($i % 2 === 0 ? 2 : 1);
            $total += $valor > 9 ? $valor - 9 : $valor;
        }
        $digito = (10 - $total % 10) % 10;
        return $digito === (int) $cedula[9];
    }
}
PHP
  perl -pi -e "s|^use Acme\\\\Crm\\\\Validation\\\\RucValidator;|use Acme\\\\Crm\\\\Validation\\\\CedulaValidator;\nuse Acme\\\\Crm\\\\Validation\\\\RucValidator;|;
               s|^        // TODO: tipo 'cedula'|        if (\\\$tipo === 'cedula' && !CedulaValidator::validarCedula(\\\$id)) {\n            \\\$errors['identificacion'] = 'Cédula inválida';\n        }|" src/Customers/CustomerForm.php
}
expect() {
  expect_line '^  \[red\] src/Validation/CedulaValidator.php: .*same structure as code in src/Validation/RucValidator.php'
  expect_checks PFPP
  expect_line 'A RED copy is not a matter of justification'
}
