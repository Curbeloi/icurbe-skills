# Paths listed in .reuse-before-write-ignore are left out of the audit (and of find-similar).
FIXTURE=1-ts-reuse-format-currency
change() {
  printf '# vendored, not ours\nlegacy/\n' > .reuse-before-write-ignore
  mkdir -p legacy
  printf 'export const f = () => { try { return 1 } catch (e) {} };\n' > legacy/old.ts
}
expect() { expect_no_red; expect_no_line 'legacy/'; }
