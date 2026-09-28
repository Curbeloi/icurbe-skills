#!/usr/bin/env bash
# audit-diff.sh: audit your change for duplication, symptom patches, touched tests, new
# dependencies and copy-paste before you call the task done. Run it inside the repository.
#
#   audit-diff.sh           # working tree + staged + untracked files vs HEAD
#   audit-diff.sh main      # everything since the merge-base with main
#
# It only informs: it always exits 0 and ends with a GREEN / YELLOW / RED summary. RED means
# "look at this before delivering", not "this is wrong". Read-only; no network. Runs jscpd on the
# changed files only when jscpd is already installed (never downloads it).

set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"
rbw_color

MAX_ITEMS=15

case "${1:-}" in -h|--help) sed -n '2,11p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;; esac

if ! rbw_in_git; then
  echo "audit-diff.sh: not inside a git repository; nothing to compare against."
  exit 0
fi
cd "$(git rev-parse --show-toplevel)" || exit 0

EMPTY_TREE=$(git hash-object -t tree /dev/null)
BASE_ARG=${1:-HEAD}
if git rev-parse --verify -q "$BASE_ARG^{commit}" >/dev/null; then
  if [ "$BASE_ARG" = "HEAD" ]; then BASE=HEAD
  else BASE=$(git merge-base "$BASE_ARG" HEAD 2>/dev/null || echo "$BASE_ARG"); fi
elif [ "$BASE_ARG" = "HEAD" ]; then
  BASE=$EMPTY_TREE    # repository without commits yet
else
  echo "audit-diff.sh: unknown base '$BASE_ARG'."; exit 0
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/rbw.XXXXXX")
trap 'rm -rf "$TMP"' EXIT
RED=0; YELLOW=0
red()    { RED=$((RED + 1));       printf '  %s[red]%s %s\n' "$RBW_RED" "$RBW_OFF" "$1"; }
yellow() { YELLOW=$((YELLOW + 1)); printf '  %s[yellow]%s %s\n' "$RBW_YEL" "$RBW_OFF" "$1"; }
section() { printf '\n%s%s%s\n' "$RBW_BOLD" "$1" "$RBW_OFF"; }
cap() { awk -v max="$MAX_ITEMS" 'NR <= max { print } END { if (NR > max) printf "    ... +%d more\n", NR - max }'; }

# Exported: awk reads these regexes from ENVIRON because awk -v would eat their backslashes.
export TEST_RE='(^|/)(tests?|__tests__|specs?)/|\.(test|spec)\.[A-Za-z0-9]+$|_test\.(go|py|rs|rb)$|(^|/)test_[^/]*\.py$|Tests?\.(php|java|kt|cs)$'
export NOISE_RE='(^|/)(package-lock\.json|yarn\.lock|pnpm-lock\.yaml|composer\.lock|Cargo\.lock|poetry\.lock|uv\.lock|Gemfile\.lock|go\.sum)$|\.(min\.js|map|svg|snap)$'
export MANIFEST_RE='(^|/)(package\.json|composer\.json|Cargo\.toml|requirements[^/]*\.txt|pyproject\.toml|Pipfile|go\.mod|Gemfile|pom\.xml|build\.gradle(\.kts)?|[^/]*\.csproj)$'

# ---------------------------------------------------------------- collect the change
git -c core.quotePath=false diff --name-status -M "$BASE" -- 2>/dev/null \
  | awk -F'\t' '{ s = substr($1, 1, 1); p = (s == "R" || s == "C") ? $3 : $2; print s "\t" p }' > "$TMP/status"
git ls-files --others --exclude-standard 2>/dev/null | awk '{ print "A\t" $0 }' >> "$TMP/status"
grep -v -E "$NOISE_RE" "$TMP/status" | while IFS="$(printf '\t')" read -r st p; do
  rbw_is_excluded "$p" || printf '%s\t%s\n' "$st" "$p"
done > "$TMP/status.f"

# Added lines as path<TAB>line<TAB>text, deleted lines as path<TAB>text.
git -c core.quotePath=false diff -U0 --no-color --no-ext-diff -M "$BASE" -- 2>/dev/null | awk -v add="$TMP/added" -v del="$TMP/deleted" '
  /^diff --git / { path = ""; mpath = ""; next }
  /^--- / { mpath = substr($0, 5); sub(/^a\//, "", mpath); next }
  /^\+\+\+ / { path = substr($0, 5); if (path == "/dev/null") path = ""; else sub(/^b\//, "", path); next }
  /^@@ / { match($0, /\+[0-9]+/); ln = substr($0, RSTART + 1, RLENGTH - 1) + 0; next }
  /^\+/ { if (path != "") print path "\t" ln "\t" substr($0, 2) > add; ln++; next }
  /^-/  { p = (path != "") ? path : mpath; print p "\t" substr($0, 2) > del; next }'
touch "$TMP/added" "$TMP/deleted"
git ls-files --others --exclude-standard 2>/dev/null | while IFS= read -r f; do
  [ -f "$f" ] && grep -Iq . "$f" 2>/dev/null && awk -v p="$f" '{ print p "\t" NR "\t" $0 }' "$f"
done >> "$TMP/added"
# Keep only lines of files that survived the noise/excluded-dir filter.
cut -f2 "$TMP/status.f" > "$TMP/paths"
awk -F'\t' 'FILENAME == ARGV[1] { keep[$0] = 1; next } ($1 in keep)' "$TMP/paths" "$TMP/added" > "$TMP/added.f"
awk -F'\t' 'FILENAME == ARGV[1] { keep[$0] = 1; next } ($1 in keep)' "$TMP/paths" "$TMP/deleted" > "$TMP/deleted.f"

NFILES=$(wc -l < "$TMP/status.f" | tr -d ' ')
NADD=$(wc -l < "$TMP/added.f" | tr -d ' ')
NDEL=$(wc -l < "$TMP/deleted.f" | tr -d ' ')
printf '%sreuse-before-write diff audit%s  base: %s\n' "$RBW_BOLD" "$RBW_OFF" "$( [ "$BASE" = "$EMPTY_TREE" ] && echo "(empty repository)" || echo "$BASE_ARG" )"
printf '%s files changed, +%s -%s lines (lockfiles and generated files ignored)\n' "$NFILES" "$NADD" "$NDEL"
if [ "$NFILES" -eq 0 ]; then
  printf '\n%sGREEN%s: no changes to audit.\n' "$RBW_GRN" "$RBW_OFF"; exit 0
fi

# ---------------------------------------------------------------- 1. new files
section "1. New files: is each one justified by the Phase 3 decision?"
awk -F'\t' '$1 == "A" { print $2 }' "$TMP/status.f" > "$TMP/newfiles"
if [ -s "$TMP/newfiles" ]; then
  n=$(wc -l < "$TMP/newfiles" | tr -d ' ')
  yellow "$n new file(s):"
  sed 's/^/      /' "$TMP/newfiles" | cap
else
  echo "  none"
fi

# ---------------------------------------------------------------- 2. new definitions
section "2. New functions/classes and similar existing names"
# Sections 2 and 3 look at code only: docs, data files and tests are not where duplication or
# swallowed errors hurt (tests legitimately catch exceptions to assert on them).
awk -F'\t' '$1 !~ /\.(md|mdx|txt|rst|json|ya?ml|toml|xml|csv|svg|html?|lock|ini|cfg|env)$/ && $1 !~ ENVIRON["TEST_RE"]' "$TMP/added.f" > "$TMP/added.code"
awk -F'\t' '{ print $1 ":" $2 ":" $3 }' "$TMP/added.code" \
  | rbw_extract_defs | sort -u > "$TMP/newdefs"
if [ ! -s "$TMP/newdefs" ]; then
  echo "  none"
else
  rbw_search "$RBW_DEF_RE" | rbw_extract_defs | awk -F'\t' '{ split($2, a, ":") } a[1] !~ ENVIRON["TEST_RE"]' | sort -u > "$TMP/alldefs"
  cut -f1 "$TMP/alldefs" | rbw_split_words > "$TMP/alldefs.w"; paste "$TMP/alldefs" "$TMP/alldefs.w" > "$TMP/alldefs.idx"
  cut -f1 "$TMP/newdefs" | rbw_split_words > "$TMP/newdefs.w"; paste "$TMP/newdefs" "$TMP/newdefs.w" > "$TMP/newdefs.idx"
  # For each new definition: the same name elsewhere (score 999), or a name that shares at least
  # half of its meaningful words (score = percentage). Generic words do not count as meaningful.
  awk -F'\t' "$RBW_AWK_STEM"'
    BEGIN {
      split("get set is has to from with by of for and the new old do on in at as data value values item items info util utils helper helpers impl base default main init handle handler make run process test tests spec it use props prop type types state context provider component options option config params param args result response request action event dialog modal button view page list hook dto interface model models service services controller manager factory builder wrapper internal", sw, " ")
      for (i in sw) stop[sw[i]] = 1
    }
    function sig(words, out,   k, i, w, c) {
      k = split(words, w, " "); c = 0
      for (i = 1; i <= k; i++) if (length(w[i]) >= 3 && !(w[i] in stop)) out[++c] = w[i]
      return c
    }
    FILENAME == ARGV[1] {
      n++; name[n] = $1; loc[n] = $2; isnew[$2] = 1
      split("", tmp); nw[n] = sig($3, tmp)
      for (i = 1; i <= nw[n]; i++) word[n, i] = stem(tmp[i])
      next
    }
    ($2 in isnew) { next }
    {
      split("", ow); m = sig($3, ow)
      for (j = 1; j <= n; j++) {
        if ($1 == name[j]) { print name[j] "\t" loc[j] "\t999\t" $1 "\t" $2; continue }
        if (nw[j] == 0 || m == 0) continue
        shared = 0
        for (a = 1; a <= nw[j]; a++) for (b = 1; b <= m; b++) if (index(ow[b], word[j, a]) == 1) { shared++; break }
        big = (nw[j] > m) ? nw[j] : m
        # One shared word is at most a weak match: EventBlock is not BlockAction.
        if (shared * 2 >= big) print name[j] "\t" loc[j] "\t" (shared == 1 ? 50 : int(100 * shared / big)) "\t" $1 "\t" $2
      }
    }' "$TMP/newdefs.idx" "$TMP/alldefs.idx" | sort -t "$(printf '\t')" -k1,1 -k3,3nr > "$TMP/similar"

  # Names this change defines more than once (the diff duplicating itself).
  # Single lowercase words (approve, render) are too generic to call a duplicate.
  cut -f1 "$TMP/newdefs" | sort | uniq -d | grep -E '^[A-Z]|[a-z0-9][A-Z]|_' > "$TMP/selfdup"
  while IFS= read -r id; do
    yellow "$id is defined $(awk -F'\t' -v id="$id" '$1 == id' "$TMP/newdefs" | wc -l | tr -d ' ') times in this change; define it once and import it:"
    awk -F'\t' -v id="$id" '$1 == id { print "      " $2 }' "$TMP/newdefs" | cap
  done < "$TMP/selfdup"

  count=0; quiet=0
  while IFS="$(printf '\t')" read -r id where; do
    exact=$(awk -F'\t' -v id="$id" '$1 == id && $3 == 999 { print "      " $5 }' "$TMP/similar" | head -n 3)
    # Strong matches (more than half the words) up to 3; otherwise the best half-match, marked weak.
    near=$(awk -F'\t' -v id="$id" -v at="$where" '$1 == id && $2 == at && $3 != 999 {
             if ($3 > 50 && strong < 3) { strong++; print "      " $4 "  " $5 }
             else if ($3 == 50 && !strong && !weak) { weak = 1; w = "      " $4 "  " $5 "  (weak)" }
           } END { if (!strong && weak) print w }' "$TMP/similar")
    refs=$(rbw_search "(^|[^A-Za-z0-9_\$])$id([^A-Za-z0-9_\$]|\$)" | wc -l | tr -d ' ')
    if [ -z "$exact" ] && [ -z "$near" ] && [ "$refs" -gt 1 ]; then quiet=$((quiet + 1)); continue; fi
    count=$((count + 1)); [ "$count" -gt "$MAX_ITEMS" ] && { echo "  ... more new definitions not shown"; break; }
    if [ -n "$exact" ]; then
      yellow "$id ($where): the same name is already defined elsewhere (fine for an interface method or override; a duplicate otherwise):"; printf '%s\n' "$exact"
    elif [ -n "$near" ]; then
      yellow "$id ($where): similar existing names; reuse or unify instead?"; printf '%s\n' "$near"
    fi
    if [ "$refs" -le 1 ]; then
      yellow "$id ($where) is not referenced anywhere else (dead on arrival, or is the old version still the one in use?)"
    fi
  done < "$TMP/newdefs"
  [ "$quiet" -gt 0 ] && printf '  %s[ok]%s %s other new definition(s): no similar names, referenced\n' "$RBW_GRN" "$RBW_OFF" "$quiet"
fi

# ---------------------------------------------------------------- 3. fallbacks and suppressions
section "3. Error swallowing, fallbacks and suppressions (code, not tests): cause fixed or symptom hidden?"
awk -F'\t' '
  function show(kind) { printf "%s\t%s:%s\t%s\n", kind, $1, $2, substr(t, 1, 110) }
  {
    t = $3; sub(/^[[:space:]]+/, "", t)
    if (t ~ /^(\/\/|#|\*|\/\*|<!--)/ && t !~ /(@ts-ignore|@ts-expect-error|eslint-disable|noqa|type: *ignore|phpcs:ignore|phpstan-ignore|NOSONAR|nolint)/) next
    if (t ~ /catch[[:space:]]*(\([^)]*\))?[[:space:]]*\{[[:space:]]*\}/ || t ~ /except[^:]*:[[:space:]]*(pass|\.\.\.)[[:space:]]*$/ || t ~ /rescue[[:space:]]+nil/) { show("EMPTY"); next }
    if (t ~ /(@ts-ignore|@ts-expect-error|eslint-disable|# *noqa|type: *ignore|#\[allow\(|@SuppressWarnings|phpcs:ignore|@phpstan-ignore|NOSONAR|nolint)/) { show("suppress"); next }
    if ($1 ~ /\.php$/ && t ~ /(^|[^A-Za-z0-9_"'\''])@(new[[:space:]]|[$a-zA-Z_\\]+[[:space:]]*\()/) { show("suppress"); next }
    if (t ~ /(^|[^A-Za-z0-9_])(try|catch|except|rescue)([^A-Za-z0-9_]|$)/) { show("try/catch"); next }
    if (t ~ /\?\?|\|\|[[:space:]]*(""|'\'''\''|0|\[\]|\{\}|null|undefined|false|-1)|unwrap_or|\.ok\(\)|[[:space:]]or[[:space:]]+(None|0|""|'\'''\''|\[\]|\{\})|\.get\([^,()]+,[^)]+\)|getOrDefault|orElse\(/) { show("fallback"); next }
    if ($1 ~ /\.php$/ && t ~ /\?:/) { show("fallback"); next }
    if (t ~ /(^|[^A-Za-z0-9_])(retry|retries|sleep|backoff)([^A-Za-z0-9_]|$)/) { show("retry"); next }
  }' "$TMP/added.code" > "$TMP/fallbacks"
if [ -s "$TMP/fallbacks" ]; then
  for k in EMPTY suppress try/catch fallback retry; do
    n=$(awk -F'\t' -v k="$k" '$1 == k' "$TMP/fallbacks" | wc -l | tr -d ' ')
    [ "$n" -eq 0 ] && continue
    case "$k" in
      EMPTY) red "$n empty catch/except block(s): the error is swallowed" ;;
      suppress) red "$n error or linter suppression(s) added" ;;
      *) yellow "$n $k line(s) added" ;;
    esac
    awk -F'\t' -v k="$k" '$1 == k { printf "      %s  %s\n", $2, $3 }' "$TMP/fallbacks" | cap
  done
else
  echo "  none"
fi

# ---------------------------------------------------------------- 4. tests
section "4. Tests touched: was the test wrong, or was it adjusted to pass?"
awk -F'\t' '$2 ~ ENVIRON["TEST_RE"]' "$TMP/status.f" > "$TMP/tests"
if [ ! -s "$TMP/tests" ]; then
  echo "  none"
else
  export ASSERT_RE='assert|expect\(|should|check\(|assertEquals|assertSame|assert_eq|toBe|toEqual|@Test'
  export SKIP_RE='\.skip\(|(^|[^a-z])x(it|describe|test)\(|\.only\(|@skip|mark\.skip|#\[ignore\]|markTestSkipped|@Disabled|@Ignore|t\.Skip\('
  while IFS="$(printf '\t')" read -r st f; do
    if [ "$st" = "A" ]; then
      printf '  %s[new]%s %s\n' "$RBW_GRN" "$RBW_OFF" "$f"
    else
      rm_asserts=$(awk -F'\t' -v f="$f" '$1 == f && $2 ~ ENVIRON["ASSERT_RE"]' "$TMP/deleted.f" | wc -l | tr -d ' ')
      if [ "$rm_asserts" -gt 0 ]; then
        red "$f: $rm_asserts assertion line(s) changed or removed in an existing test"
        awk -F'\t' -v f="$f" '$1 == f && $2 ~ ENVIRON["ASSERT_RE"] { t = $2; sub(/^[[:space:]]+/, "", t); print "      - " substr(t, 1, 110) }' "$TMP/deleted.f" | cap
      else
        yellow "$f: existing test modified (no assertion removed)"
      fi
    fi
    awk -F'\t' -v f="$f" '$1 == f && $3 ~ ENVIRON["SKIP_RE"] { print $2 }' "$TMP/added.f" > "$TMP/skips"
    if [ -s "$TMP/skips" ]; then red "$f: test skipped/focused at line(s) $(tr '\n' ' ' < "$TMP/skips")"; fi
  done < "$TMP/tests"
fi

# ---------------------------------------------------------------- 5. dependencies
section "5. Dependency manifests: does a new dependency duplicate an installed one?"
awk -F'\t' '$2 ~ ENVIRON["MANIFEST_RE"] { print $2 }' "$TMP/status.f" > "$TMP/manifests"
if [ ! -s "$TMP/manifests" ]; then
  echo "  none"
else
  while IFS= read -r m; do
    yellow "$m changed; added lines:"
    awk -F'\t' -v f="$m" '$1 == f && $3 !~ /"version"[[:space:]]*:/ && $3 ~ /[^[:space:]]/ { t = $3; sub(/^[[:space:]]+/, "", t); print "      + " t }' "$TMP/added.f" | cap
  done < "$TMP/manifests"
fi

# ---------------------------------------------------------------- 6. copied lines
# Name checks miss a copied algorithm under a new name. Look for added code lines that already
# exist verbatim (whitespace aside) elsewhere in the repository. Trivial lines and boilerplate
# found in many files (imports, declare(strict_types=1), closing braces) do not count.
section "6. Added code that already exists elsewhere: extract and reuse instead of copying?"
awk -F'\t' '
  { t = $3; gsub(/[[:space:]]+/, " ", t); sub(/^ /, "", t); sub(/ $/, "", t) }
  length(t) < 18 { next }
  t ~ /^(import|use|require|include|from|export \{|#include|package|namespace|using|<\?php|\/\/|#|\*|\/\*)/ { next }
  { print t "\t" $1 ":" $2 }' "$TMP/added.code" > "$TMP/added.norm"
if [ -s "$TMP/added.norm" ]; then
  rbw_list_files > "$TMP/repo.files"
  # One pass over the repository: for each added line, the other places where it appears.
  # xargs may split the file list; every awk call gets added.norm first. LC_ALL=C: binary-safe.
  # shellcheck disable=SC2016  # the $ are awk fields, not shell expansions
  tr '\n' '\0' < "$TMP/repo.files" | LC_ALL=C xargs -0 awk '
    FILENAME == ARGV[1] { split($0, a, "\t"); want[a[1]] = 1; here[a[2]] = 1; next }
    {
      t = $0; gsub(/[[:space:]]+/, " ", t); sub(/^ /, "", t); sub(/ $/, "", t)
      if ((t in want) && !((FILENAME ":" FNR) in here)) print t "\t" FILENAME ":" FNR
    }' "$TMP/added.norm" 2>/dev/null > "$TMP/seen"
  # Drop boilerplate (lines present in more than 3 other files), then pair each changed file
  # with the file its lines come from, counting distinct copied lines.
  awk -F'\t' '
    FILENAME == ARGV[1] { split($2, a, ":"); if (!(($1, a[1]) in f)) { f[$1, a[1]] = 1; nf[$1]++ } seen[$1] = seen[$1] "\n" $2; next }
    ($1 in nf) && nf[$1] <= 3 {
      split($2, a, ":"); src = a[1]; n = split(seen[$1], locs, "\n")
      for (i = 2; i <= n; i++) { split(locs[i], b, ":"); if (b[1] != src && !((src, b[1], $1) in done)) { done[src, b[1], $1] = 1; pair[src "\t" b[1]]++ } }
    }
    END { for (k in pair) if (pair[k] >= 3) print pair[k] "\t" k }' "$TMP/seen" "$TMP/added.norm" \
    | sort -t "$(printf '\t')" -k1,1nr > "$TMP/copied"
fi
if [ -s "$TMP/copied" ]; then
  while IFS="$(printf '\t')" read -r n changed from; do
    msg="$changed: $n added lines already exist in $from; extract the shared code and call it from both"
    if [ "$n" -ge 6 ]; then red "$msg"; else yellow "$msg"; fi
  done < "$TMP/copied"
else
  echo "  none"
fi

# ---------------------------------------------------------------- 7. copy-paste (jscpd)
section "7. Copy-paste between the changed files (jscpd)"
JSCPD=''
if [ -x node_modules/.bin/jscpd ]; then JSCPD=node_modules/.bin/jscpd
elif command -v jscpd >/dev/null 2>&1; then JSCPD=jscpd; fi
if [ -z "$JSCPD" ]; then
  printf '  %sskipped: jscpd is not installed (npm i -g jscpd to enable)%s\n' "$RBW_DIM" "$RBW_OFF"
else
  : > "$TMP/cpd.files"
  awk -F'\t' '$1 != "D" { print $2 }' "$TMP/status.f" | while IFS= read -r f; do
    [ -f "$f" ] && printf '%s\n' "$f" >> "$TMP/cpd.files"
  done
  if [ -s "$TMP/cpd.files" ]; then
    # shellcheck disable=SC2046
    "$JSCPD" --silent --reporters json --output "$TMP/cpd" --min-lines 5 --min-tokens 40 \
      $(head -n 200 "$TMP/cpd.files" | tr '\n' ' ') >/dev/null 2>&1
    if [ -f "$TMP/cpd/jscpd-report.json" ]; then
      awk '
        /"name":/ { gsub(/.*"name":[[:space:]]*"|",?[[:space:]]*$/, ""); nm = $0 }
        /"start":/ { gsub(/[^0-9]/, ""); st = $0 }
        /"end":/   { gsub(/[^0-9]/, ""); if (nm != "") { side[++k] = nm ":" st "-" $0; nm = "" } }
        END { for (i = 1; i + 1 <= k; i += 2) print side[i] "  ==  " side[i + 1] }' "$TMP/cpd/jscpd-report.json" > "$TMP/clones"
      if [ -s "$TMP/clones" ]; then
        red "$(wc -l < "$TMP/clones" | tr -d ' ') duplicated block(s): parametrise instead of copying?"
        sed 's/^/      /' "$TMP/clones" | cap
      else
        echo "  no duplicated blocks"
      fi
    else
      printf '  %sjscpd produced no report%s\n' "$RBW_DIM" "$RBW_OFF"
    fi
  fi
fi

# ---------------------------------------------------------------- summary
section "Summary"
if [ "$RED" -gt 0 ]; then
  printf '  %sRED%s: %s item(s) need a look, %s to justify.\n' "$RBW_RED" "$RBW_OFF" "$RED" "$YELLOW"
elif [ "$YELLOW" -gt 0 ]; then
  printf '  %sYELLOW%s: %s item(s) to justify.\n' "$RBW_YEL" "$RBW_OFF" "$YELLOW"
else
  printf '  %sGREEN%s: nothing flagged.\n' "$RBW_GRN" "$RBW_OFF"
fi
echo "  Answer the Phase 4 checklist in SKILL.md for every flagged item; dead code and diff size need your judgement."
exit 0
