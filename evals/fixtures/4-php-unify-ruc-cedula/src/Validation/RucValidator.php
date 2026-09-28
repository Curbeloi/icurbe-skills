<?php
declare(strict_types=1);

namespace Acme\Crm\Validation;

/** RUC de persona natural (Ecuador): 10 dígitos de cédula + "001". */
final class RucValidator
{
    public static function validarRuc(string $ruc): bool
    {
        if (!preg_match('/^\d{13}$/', $ruc)) {
            return false;
        }
        $provincia = (int) substr($ruc, 0, 2);
        if ($provincia < 1 || $provincia > 24) {
            return false;
        }
        if ((int) $ruc[2] >= 6) {
            return false;
        }
        $suma = 0;
        for ($i = 0; $i < 9; $i++) {
            $d = (int) $ruc[$i] * ($i % 2 === 0 ? 2 : 1);
            $suma += $d > 9 ? $d - 9 : $d;
        }
        $verificador = (10 - $suma % 10) % 10;
        return $verificador === (int) $ruc[9] && substr($ruc, 10) === '001';
    }
}
