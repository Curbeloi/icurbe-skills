<?php
declare(strict_types=1);

namespace Acme\Facturacion\Invoice;

use Acme\Facturacion\Tax\IvaCalculator;

final class TotalService
{
    public function __construct(private IvaCalculator $iva = new IvaCalculator())
    {
    }

    public function total(Factura $factura): float
    {
        return $factura->subtotal + $this->iva->calcularIVA($factura->subtotal, $factura->tarifaIva);
    }
}
