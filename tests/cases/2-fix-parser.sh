# The right answer to eval 2: the parser reads the node the XML has.
FIXTURE=2-php-root-cause-iva-null
CHECK=2
FINAL_MESSAGE='Causa raíz: el parser XML leía el nodo tarifaIva, pero el XML trae <tarifa>.'
change() { perl -pi -e 's/tarifaIva\) \? \(float\) \$impuesto->tarifaIva/tarifa) ? (float) \$impuesto->tarifa/' src/Xml/FacturaParser.php; }
expect() { expect_no_red; expect_checks PPPP; }
