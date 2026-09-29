# RBW_EXCLUDE takes globs. They must reach the filter as patterns: expanded by the shell against
# the files in the root, "*.gen.ts" would only exclude root.gen.ts.
FIXTURE=1-ts-reuse-format-currency
export RBW_EXCLUDE='*.gen.ts'
change() {
  printf 'export const a = () => { try { return 1 } catch (e) {} };\n' > root.gen.ts
  printf 'export const b = () => { try { return 2 } catch (e) {} };\n' > src/api.gen.ts
}
expect() { expect_no_red; expect_no_line '\.gen\.ts'; }
