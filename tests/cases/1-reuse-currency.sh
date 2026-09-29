# The right answer to eval 1: reuse formatCurrency. Nothing to flag.
FIXTURE=1-ts-reuse-format-currency
CHECK=1
SEARCH=(currency NumberFormat)
change() {
  perl -pi -e 's|^(import \{ formatDate \} from "../utils/dates.ts";)|$1\nimport { formatCurrency } from "../utils/money.ts";|;
               s|Total: \$\{invoiceTotal\(invoice\)\}|Total: \${formatCurrency(invoiceTotal(invoice), "USD")}|' src/views/invoiceView.ts
}
expect() {
  expect_summary GREEN
  expect_checks PPPP
  expect_found 'src/utils/money.ts:[0-9]+ +formatCurrency'   # by name
  expect_found 'NumberFormat +src/utils/money.ts'           # by behaviour: the primitive it would call
}
