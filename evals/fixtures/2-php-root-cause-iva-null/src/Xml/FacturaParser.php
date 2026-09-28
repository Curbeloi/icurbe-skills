<?php
declare(strict_types=1);

namespace Acme\Facturacion\Xml;

use Acme\Facturacion\Invoice\Factura;

final class FacturaParser
{
    public function parse(string $xml): Factura
    {
        $doc = new \SimpleXMLElement($xml);
        $info = $doc->infoFactura;
        $impuesto = $info->totalConImpuestos->totalImpuesto;

        return new Factura(
            numero: (string) $doc->infoTributaria->secuencial,
            subtotal: (float) $info->totalSinImpuestos,
            tarifaIva: isset($impuesto->tarifaIva) ? (float) $impuesto->tarifaIva : null,
        );
    }
}
