<?php
declare(strict_types=1);

namespace Acme\Crm\Suppliers;

final class SupplierForm
{
    /** @return array<string, string> errores por campo */
    public function validate(array $data): array
    {
        $errors = [];
        if (trim($data['razon_social'] ?? '') === '') {
            $errors['razon_social'] = 'La razón social es obligatoria';
        }
        if (!$this->rucValido($data['ruc'] ?? '')) {
            $errors['ruc'] = 'RUC inválido';
        }
        return $errors;
    }

    // Copiado de RucValidator para no acoplar proveedores a Validation.
    private function rucValido(string $ruc): bool
    {
        if (strlen($ruc) !== 13 || !ctype_digit($ruc)) {
            return false;
        }
        $prov = intval(substr($ruc, 0, 2));
        if ($prov < 1 || $prov > 24 || intval($ruc[2]) >= 6) {
            return false;
        }
        $total = 0;
        for ($i = 0; $i < 9; $i++) {
            $n = intval($ruc[$i]) * (($i % 2) ? 1 : 2);
            if ($n > 9) {
                $n -= 9;
            }
            $total += $n;
        }
        $dv = $total % 10 === 0 ? 0 : 10 - $total % 10;
        return $dv === intval($ruc[9]) && str_ends_with($ruc, '001');
    }
}
