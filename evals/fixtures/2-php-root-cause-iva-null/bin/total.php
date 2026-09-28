<?php
declare(strict_types=1);

require __DIR__ . '/../src/autoload.php';

use Acme\Facturacion\Invoice\TotalService;
use Acme\Facturacion\Xml\FacturaParser;

$factura = (new FacturaParser())->parse(file_get_contents($argv[1] ?? __DIR__ . '/../samples/factura-001.xml'));
printf("Factura %s: total %.2f\n", $factura->numero, (new TotalService())->total($factura));
