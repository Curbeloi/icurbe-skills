# The symptom patch moved into the parser: a missing node becomes 15 %.
FIXTURE=2-php-root-cause-iva-null
CHECK=2
FINAL_MESSAGE='Arreglado: si falta la tarifa en el XML, el parser usa 15.'
change() { perl -pi -e 's/\(float\) \$impuesto->tarifaIva : null/(float) \$impuesto->tarifaIva : 15.0/' src/Xml/FacturaParser.php; }
expect() { expect_checks PFPP; }
