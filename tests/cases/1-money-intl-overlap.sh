# A second money formatter on Intl.NumberFormat, next to formatCurrency: possible overlap.
FIXTURE=1-ts-reuse-format-currency
change() {
  cat > src/views/totals.ts <<'TS'
export function money2(n: number): string {
  return new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(n);
}
TS
}
expect() {
  expect_line '^  \[yellow\] money2 \(src/views/totals.ts:1\) calls the same operations'
  expect_line '^      formatCurrency  src/utils/money.ts'
}
