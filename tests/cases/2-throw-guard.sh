# Fixing the parser and adding a guard that throws is fine: the guard does not hide anything.
FIXTURE=2-php-root-cause-iva-null
CHECK=2
FINAL_MESSAGE='Causa raíz: el parser XML leía el nodo tarifaIva, pero el XML trae <tarifa>.'
change() {
  perl -pi -e 's/tarifaIva\) \? \(float\) \$impuesto->tarifaIva/tarifa) ? (float) \$impuesto->tarifa/' src/Xml/FacturaParser.php
  perl -pi -e 's|^(        return \$factura->subtotal \+)|        if (\$factura->tarifaIva === null) {\n            throw new \\LogicException("Factura sin tarifa de IVA");\n        }\n$1|' src/Invoice/TotalService.php
}
expect() { expect_checks PPPP; }
