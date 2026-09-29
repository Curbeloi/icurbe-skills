# shellcheck shell=bash
# Expectations for the cases in tests/cases/. Sourced by tests/run.sh; each case's expect()
# calls them. They read $AUDIT_OUT (audit-diff.sh), except expect_found ($SEARCH_OUT,
# find-similar.sh) and expect_checks ($CHECK_OUT, the eval check). A failed expectation prints what was expected and sets FAILED; the case fails at the end.

FAILED=0
missed() { FAILED=1; printf '  expected %s\n' "$1"; }

# expect_line REGEX: some output line matches the extended regular expression.
expect_line() { printf '%s\n' "$AUDIT_OUT" | grep -Eq -- "$1" || missed "a line matching: $1"; }

# expect_no_line REGEX: no output line matches.
expect_no_line() {
  local hit
  hit=$(printf '%s\n' "$AUDIT_OUT" | grep -E -- "$1" | head -n 3)
  [ -z "$hit" ] || missed "no line matching: $1, got:
$hit"
}

# expect_summary GREEN|YELLOW|RED: the audit's overall verdict.
expect_summary() { printf '%s\n' "$AUDIT_OUT" | grep -Eq "^  $1:" || missed "summary $1"; }

expect_no_red() { expect_no_line '^  \[red\]'; }

# expect_found REGEX: some line of the find-similar.sh output matches.
expect_found() { printf '%s\n' "$SEARCH_OUT" | grep -Eq -- "$1" || missed "find-similar.sh to show: $1"; }

# expect_quiet_section N: audit section N flags nothing (it prints "none" or only [ok] lines).
expect_quiet_section() {
  local flagged
  flagged=$(printf '%s\n' "$AUDIT_OUT" | awk -v n="$1" '
    $0 ~ "^" n "\\. " { on = 1; next }
    on && (/^[0-9]+\. / || /^Summary/) { on = 0 }
    on && /^  \[(red|yellow)\]/' | head -n 3)
  [ -z "$flagged" ] || missed "nothing flagged in section $1, got:
$flagged"
}

# expect_checks PFPP: the PASS/FAIL sequence of an eval check, in order.
expect_checks() {
  local got
  got=$(printf '%s\n' "$CHECK_OUT" | grep -E '^(PASS|FAIL)' | cut -c1 | tr -d '\n')
  [ "$got" = "$1" ] || missed "checks $1, got ${got:-nothing}"
}
