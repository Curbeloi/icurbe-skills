<?php
declare(strict_types=1);

namespace Acme\Facturacion\Invoice;

final class Factura
{
    public function __construct(
        public readonly string $numero,
        public readonly float $subtotal,
        public readonly ?float $tarifaIva,
    ) {
    }
}
