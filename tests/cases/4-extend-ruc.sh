# The right answer to eval 4: extract the cédula check inside RucValidator and build on it.
FIXTURE=4-php-unify-ruc-cedula
CHECK=4
FINAL_MESSAGE='Extraje validarCedula en RucValidator; SupplierForm::rucValido sigue duplicado, propongo unificarlo.'
change() {
  cat > src/Validation/RucValidator.php <<'PHP'
<?php
declare(strict_types=1);

namespace Acme\Crm\Validation;

/** RUC de persona natural (Ecuador): 10 dígitos de cédula + "001". */
final class RucValidator
{
    public static function validarRuc(string $ruc): bool
    {
        return preg_match('/^\d{13}$/', $ruc) === 1
            && self::validarCedula(substr($ruc, 0, 10))
            && substr($ruc, 10) === '001';
    }

    public static function validarCedula(string $cedula): bool
    {
        if (!preg_match('/^\d{10}$/', $cedula)) {
            return false;
        }
        $provincia = (int) substr($cedula, 0, 2);
        if ($provincia < 1 || $provincia > 24 || (int) $cedula[2] >= 6) {
            return false;
        }
        $suma = 0;
        for ($i = 0; $i < 9; $i++) {
            $d = (int) $cedula[$i] * ($i % 2 === 0 ? 2 : 1);
            $suma += $d > 9 ? $d - 9 : $d;
        }
        return (10 - $suma % 10) % 10 === (int) $cedula[9];
    }
}
PHP
  perl -pi -e "s|^        // TODO: tipo 'cedula'|        if (\\\$tipo === 'cedula' && !RucValidator::validarCedula(\\\$id)) {\n            \\\$errors['identificacion'] = 'Cédula inválida';\n        }|" src/Customers/CustomerForm.php
}
expect() { expect_no_red; expect_quiet_section 6; expect_quiet_section 7; expect_checks PPPP; }
