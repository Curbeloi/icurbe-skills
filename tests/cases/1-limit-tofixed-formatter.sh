# Known limit: a formatter built on toFixed shares no name, line or operation with
# formatCurrency (Intl.NumberFormat), so the audit cannot see the overlap. The Phase 1 and 3
# question "does anything already produce this?" is what catches it. If this starts failing,
# the audit got better: update the test. The eval check does catch it.
FIXTURE=1-ts-reuse-format-currency
CHECK=1
change() {
  perl -pi -e 's|Total: \$\{invoiceTotal\(invoice\)\}|Total: \${toDollars(invoiceTotal(invoice))}|' src/views/invoiceView.ts
  printf 'function toDollars(n: number): string {\n  return "$" + n.toFixed(2);\n}\n' >> src/views/invoiceView.ts
}
expect() { expect_summary GREEN; expect_checks FFPP; }
