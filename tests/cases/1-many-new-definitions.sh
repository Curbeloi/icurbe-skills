# Past 20 new names the references are counted in one pass over the repository instead of one
# search per name; both ways must agree on what is referenced.
FIXTURE=1-ts-reuse-format-currency
change() {
  mkdir -p src/steps
  for i in $(seq 1 25); do printf 'export function stepNumber%s(): number {\n  return %s;\n}\n' "$i" "$i"; done > src/steps/steps.ts
  { echo 'import * as s from "./steps.ts";'
    echo 'export const all = ['
    for i in $(seq 1 24); do printf '  s.stepNumber%s(),\n' "$i"; done
    echo '];'; } > src/steps/all.ts
}
expect() {
  expect_line '^  \[yellow\] stepNumber25 \(src/steps/steps.ts:73\) is not referenced'
  expect_no_line 'stepNumber(1|12|24) \(.* is not referenced'
}
