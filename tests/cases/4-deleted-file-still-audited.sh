# A tracked file deleted in the working tree must not stop the copied-lines search: awk used to
# abort the whole batch on the missing file and the section printed "none".
FIXTURE=4-php-unify-ruc-cedula
change() {
  rm src/Customers/CustomerForm.php
  cat > src/Validation/Copied.php <<'PHP'
<?php
function copied(string $ruc, int $suma): bool
{
        if (!preg_match('/^\d{13}$/', $ruc)) {
            return false;
        }
        $provincia = (int) substr($ruc, 0, 2);
        if ($provincia < 1 || $provincia > 24) {
            return false;
        }
        $verificador = (10 - $suma % 10) % 10;
        return $verificador === (int) $ruc[9];
}
PHP
}
expect() {
  expect_line '^  \[(yellow|red)\] src/Validation/Copied.php: .* in src/Validation/RucValidator.php'
}
