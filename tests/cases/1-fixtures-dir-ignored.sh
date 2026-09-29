# Test data under fixtures/ is not project code: duplicates and swallowed errors there are on purpose.
FIXTURE=1-ts-reuse-format-currency
change() {
  mkdir -p fixtures
  printf 'export const f = () => { try { return 1 } catch (e) {} };\n' > fixtures/sample.ts
  cp src/utils/money.ts fixtures/money-copy.ts
}
expect() { expect_summary GREEN; }
