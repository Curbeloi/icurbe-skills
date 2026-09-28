<?php
declare(strict_types=1);

namespace Acme\Facturacion\Tax;

final class IvaCalculator
{
    /** IVA de una base imponible con la tarifa en porcentaje (15 = 15 %). */
    public function calcularIVA(float $base, float $tarifa): float
    {
        return round($base * $tarifa / 100, 2);
    }
}
