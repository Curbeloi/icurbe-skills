FIXTURE=1-ts-reuse-format-currency
change() {
  echo 'export const toDollars = (n: number) => { try { return "$" + n } catch (e) {} };' > src/utils/dollars.ts
}
expect() { expect_line '^  \[red\] 1 empty catch/except block'; }
