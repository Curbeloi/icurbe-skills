<?php
declare(strict_types=1);

require __DIR__ . '/../src/autoload.php';

use Acme\Facturacion\Invoice\TotalService;
use Acme\Facturacion\Tax\IvaCalculator;
use Acme\Facturacion\Xml\FacturaParser;

$fails = 0;
function check(string $name, bool $ok): void { global $fails; echo ($ok ? 'ok   ' : 'FAIL ') . $name . "\n"; $fails += $ok ? 0 : 1; }

check('calcularIVA 15%', (new IvaCalculator())->calcularIVA(100.0, 15.0) === 15.0);
$factura = (new FacturaParser())->parse(file_get_contents(__DIR__ . '/../samples/factura-001.xml'));
check('parser lee subtotal', $factura->subtotal === 100.0);
check('total con IVA', (new TotalService())->total($factura) === 115.0);
exit($fails ? 1 : 0);
