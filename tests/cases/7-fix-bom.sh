FIXTURE=7-py-root-cause-csv-bom
CHECK=7
FINAL_MESSAGE='Causa raíz: el CSV trae un BOM UTF-8, así que la columna se llama "﻿email"; lo abro con utf-8-sig.'
change() { perl -pi -e 's/encoding="utf-8"/encoding="utf-8-sig"/' app/importers/customers_csv.py; }
expect() { expect_no_red; expect_checks PPPP; }
