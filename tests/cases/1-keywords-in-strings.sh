# Words inside string literals are not code: "catch" or "??" in a message is not error handling.
# An empty-string default (|| "") still counts as a fallback; a text default ("anonymous") does not.
FIXTURE=1-ts-reuse-format-currency
change() {
  cat > src/utils/help.ts <<'TS'
export const KEYWORDS = ["try", "catch", "finally"].join(" ");
export const HELP = "Use ?? to default a value, or retry later.";
export function customerLabel(input?: string): string {
  return input || "anonymous";
}
export function customerNote(input?: string): string {
  return input || "";
}
TS
}
expect() {
  expect_line '^  \[yellow\] 1 fallback line'
  expect_no_line 'try/catch line|retry line'
}
