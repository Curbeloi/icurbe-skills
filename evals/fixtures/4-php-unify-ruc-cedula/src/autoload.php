<?php
spl_autoload_register(function (string $class): void {
    $prefix = 'Acme\\Crm\\';
    if (str_starts_with($class, $prefix)) {
        require __DIR__ . '/' . str_replace('\\', '/', substr($class, strlen($prefix))) . '.php';
    }
});
