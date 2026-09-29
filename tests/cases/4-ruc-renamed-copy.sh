# A third RUC check digit with every variable renamed is a copy, not new code.
FIXTURE=4-php-unify-ruc-cedula
change() {
  perl -pe 's/RucValidator/CedulaValidator/; s/validarRuc/validarCedula/; s/\$ruc\b/\$id/g; s/\$suma\b/\$total/g;
            s/\$d\b/\$v/g; s/\$i\b/\$k/g; s/\$provincia\b/\$prov/g; s/\$verificador\b/\$dv/g' \
    src/Validation/RucValidator.php > src/Validation/CedulaValidator.php
}
expect() {
  expect_line '^  \[red\] src/Validation/CedulaValidator.php: .*same structure as code in src/Validation/RucValidator.php'
}
