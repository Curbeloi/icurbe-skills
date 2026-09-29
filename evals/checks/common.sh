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
# added_matching REGEX [SKIP_RE] [-- PATHSPEC...]: added lines that match REGEX (extended,
# case-insensitive; comment lines ignored), as "path: line", in the changed files whose path
# SKIP_RE does not match.
added_matching() {
  local re=$1 skip='^$' f
  shift
  if [ $# -gt 0 ] && [ "$1" != -- ]; then skip=$1; shift; fi
  [ "${1:-}" = -- ] && shift
  git add -A -N . >/dev/null 2>&1
  git diff "$BASE_REF" --name-only -- "$@" | grep -Ev -- "$skip" | while IFS= read -r f; do
    [ -f "$f" ] && added "$f" | grep -Ev '^[[:space:]]*(//|#|/?\*)' | grep -Ei -- "$re" | sed "s|^|$f: |"
  done
}
# new_dependencies MANIFEST...: the lines added to these dependency manifests.
new_dependencies() { added "$@" 2>/dev/null | grep -Ei '[a-z]'; }
# no_new_dependency LABEL MANIFEST...: checks that none of the manifests gained a line.
no_new_dependency() {
  local label=$1 deps
  shift
  deps=$(new_dependencies "$@"); [ -z "$deps" ]; check "$label" $? "$(printf '%s' "$deps" | head -n 3 | tr '\n' ' ')"
}
node_tests() {
  local log r
  log=$(mktemp "${TMPDIR:-/tmp}/rbw-eval-node.XXXXXX")
  node --test test/*.test.ts > "$log" 2>&1; r=$?
  tail -n 8 "$log" | grep -E '^ℹ (pass|fail)' | tr '\n' ' '; rm -f "$log"; return $r
}
py_tests() {
  local log r
  log=$(mktemp "${TMPDIR:-/tmp}/rbw-eval-py.XXXXXX")
  python3 -m unittest > "$log" 2>&1; r=$?
  tail -n 1 "$log"; rm -f "$log"; find . -name __pycache__ -prune -exec rm -rf {} + 2>/dev/null; return $r
}
