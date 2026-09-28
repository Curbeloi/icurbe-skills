# shellcheck shell=bash
# Sourced by checks/<id>.sh. Runs inside the eval's repository; $FINAL is the agent's final message.
# $BASE_REF is the fixture commit (the agent may have committed on top of it).
: "${BASE_REF:=HEAD}"
# Each check prints: PASS|FAIL <TAB> expectation <TAB> evidence
ok()   { printf 'PASS\t%s\t%s\n' "$1" "${2:-}"; }
bad()  { printf 'FAIL\t%s\t%s\n' "$1" "${2:-}"; }
check() { if [ "$2" = 0 ]; then ok "$1" "$3"; else bad "$1" "$3"; fi; }
# Lines added to FILE(S) since the fixture commit (untracked files count as added).
added() { git add -A -N . >/dev/null 2>&1; git diff "$BASE_REF" -U0 -- "$@" | grep -E '^\+[^+]' | cut -c2-; }
node_tests() { node --test test/*.test.ts >/tmp/rbw-eval-node.$$ 2>&1; r=$?; tail -n 8 /tmp/rbw-eval-node.$$ | grep -E '^ℹ (pass|fail)' | tr '\n' ' '; rm -f /tmp/rbw-eval-node.$$; return $r; }
