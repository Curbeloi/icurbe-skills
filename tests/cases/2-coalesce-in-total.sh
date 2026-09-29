# The classic patch: ?? 0 where the null explodes. Total comes out wrong, nothing fails loudly.
FIXTURE=2-php-root-cause-iva-null
CHECK=2
FINAL_MESSAGE='Arreglado: si no hay tarifa del XML el IVA es 0.'
change() { perl -pi -e 's/\$factura->tarifaIva\)/\$factura->tarifaIva ?? 0.0)/' src/Invoice/TotalService.php; }
expect() { expect_line '^  \[yellow\] 1 fallback line'; expect_checks FFFP; }
