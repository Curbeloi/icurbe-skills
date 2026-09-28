<?php
declare(strict_types=1);

require __DIR__ . '/../src/autoload.php';

use Acme\Crm\Customers\CustomerForm;
use Acme\Crm\Suppliers\SupplierForm;
use Acme\Crm\Validation\RucValidator;

$fails = 0;
function check(string $name, bool $ok): void { global $fails; echo ($ok ? 'ok   ' : 'FAIL ') . $name . "\n"; $fails += $ok ? 0 : 1; }

check('ruc valido', RucValidator::validarRuc('1710034065001'));
check('ruc invalido', !RucValidator::validarRuc('1710034064001'));
check('cliente con ruc valido', (new CustomerForm())->validate(['nombre' => 'Ana', 'identificacion' => '1710034065001']) === []);
check('proveedor con ruc invalido', isset((new SupplierForm())->validate(['razon_social' => 'X', 'ruc' => '123'])['ruc']));
exit($fails ? 1 : 0);
