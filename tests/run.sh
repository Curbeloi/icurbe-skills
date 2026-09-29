#!/usr/bin/env bash
# Regression tests for the skill's scripts and for the eval checks. No API calls, no network.
#
#   tests/run.sh             # every case
#   tests/run.sh outbox      # only the cases whose file name contains "outbox"
#
# A case is a file in tests/cases/ that sets FIXTURE (a directory of evals/fixtures/) and defines
# change() and expect(). The runner commits a copy of the fixture, runs change() inside it (which
# must change something), runs audit-diff.sh on the result, find-similar.sh when the case sets
# SEARCH (an array of terms) and, when it sets CHECK, evals/checks/$CHECK.sh with $FINAL_MESSAGE as
# the agent's final message. expect() then asserts on the outputs (see tests/lib.sh). One case per solution: the same change is checked by the
# audit and by the eval check. Needs git, perl, node >= 23, php >= 8.1 and python3 >= 3.10.

set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
# shellcheck source-path=SCRIPTDIR source=../evals/lib.sh
. "$ROOT/evals/lib.sh"
AUDIT="$ROOT/skills/reuse-before-write/scripts/audit-diff.sh"
SIMILAR="$ROOT/skills/reuse-before-write/scripts/find-similar.sh"

missing=''
command -v git >/dev/null || missing="$missing git"
command -v perl >/dev/null || missing="$missing perl"
node -e 'process.exit(+process.versions.node.split(".")[0] >= 23 ? 0 : 1)' 2>/dev/null || missing="$missing node>=23"
php -r 'exit(PHP_VERSION_ID >= 80100 ? 0 : 1);' 2>/dev/null || missing="$missing php>=8.1"
python3 -c 'import sys; sys.exit(0 if sys.version_info >= (3, 10) else 1)' 2>/dev/null || missing="$missing python3>=3.10"
[ -z "$missing" ] || { echo "tests/run.sh: missing or too old:$missing"; exit 2; }

TMP=$(mktemp -d "${TMPDIR:-/tmp}/rbw-tests.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

run_case() (
  FIXTURE='' CHECK='' FINAL_MESSAGE=''; SEARCH=()
  # shellcheck source=/dev/null
  . "$1"
  # shellcheck source-path=SCRIPTDIR source=lib.sh
  . "$ROOT/tests/lib.sh"
  repo="$TMP/$(basename "$(dirname "$1")")-$(basename "$1" .sh)"
  fixture_copy "$FIXTURE" "$repo" && fixture_commit "$repo" || exit 1
  cd "$repo" || exit 1
  change || { echo "  change() failed"; exit 1; }
  [ -n "$(git status --porcelain)" ] || { echo "  change() changed nothing"; exit 1; }
  AUDIT_OUT=$(NO_COLOR=1 bash "$AUDIT" 2>&1)
  SEARCH_OUT=''
  [ "${#SEARCH[@]}" -eq 0 ] || SEARCH_OUT=$(NO_COLOR=1 bash "$SIMILAR" "${SEARCH[@]}" 2>&1)
  CHECK_OUT=''
  if [ -n "$CHECK" ]; then
    printf '%s\n' "$FINAL_MESSAGE" > "$repo.final"
    CHECK_OUT=$(FINAL="$repo.final" BASE_REF=$(git rev-parse HEAD) bash "$ROOT/evals/checks/$CHECK.sh" 2>&1)
  fi
  expect
  [ "$FAILED" = 0 ] && exit 0
  printf '  --- audit:\n%s\n' "$AUDIT_OUT" | sed 's/^/  /'
  [ -z "$SEARCH_OUT" ] || printf '  --- find-similar.sh:\n%s\n' "$SEARCH_OUT" | sed 's/^/  /'
  [ -z "$CHECK_OUT" ] || printf '  --- checks/%s.sh:\n%s\n' "$CHECK" "$CHECK_OUT" | sed 's/^/  /'
  exit 1
)

pass=0; fail=0
for c in "$ROOT"/tests/cases/*.sh; do
  rel=${c#"$ROOT"/}
  case "$(basename "$rel")" in *"${1:-}"*) ;; *) continue ;; esac
  if out=$(run_case "$c" 2>&1); then
    pass=$((pass + 1)); printf 'ok    %s\n' "$rel"
  else
    fail=$((fail + 1)); printf 'FAIL  %s\n%s\n' "$rel" "$out"
  fi
done
printf '\n%s passed, %s failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
