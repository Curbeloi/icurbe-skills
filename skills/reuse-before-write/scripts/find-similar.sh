#!/usr/bin/env bash
# find-similar.sh: list existing files and definitions that match domain terms, so you can reuse
# them instead of writing new ones. Run it from the repository root.
#
#   find-similar.sh <term> [term...]
#   find-similar.sh currency "format money" invoice calcularIVA
#
# A term can be one word, a phrase or an identifier in any case style. Matching is by word
# prefix, so "invoice" finds invoiceTotal, InvoiceParser and invoices.php, and "validation"
# finds validateRuc. Per term it prints matching files, definitions, and other identifiers
# (parameters, properties, keys) that mention the term. About 40 lines per term at most.
# Read-only; no network.

set -u
SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
# shellcheck source-path=SCRIPTDIR source=lib.sh
. "$SCRIPT_DIR/lib.sh"
rbw_color

MAX_FILES=10
MAX_DEFS=20
MAX_MENTIONS=8

if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
  sed -n '2,12p' "$0" | sed 's/^# \{0,1\}//'
  exit 0
fi

TMP=$(mktemp -d "${TMPDIR:-/tmp}/rbw.XXXXXX")
trap 'rm -rf "$TMP"' EXIT

# Index once, filter per term: definitions and file names, each with a words column.
rbw_search "$RBW_DEF_RE" | rbw_extract_defs > "$TMP/defs"
cut -f1 "$TMP/defs" | rbw_split_words > "$TMP/defs.words"
paste "$TMP/defs" "$TMP/defs.words" > "$TMP/defs.idx"

rbw_list_files > "$TMP/files"
sed -E 's/\.[A-Za-z0-9]+$//' "$TMP/files" | rbw_split_words > "$TMP/files.words"
paste "$TMP/files" "$TMP/files.words" > "$TMP/files.idx"

# match_words TERMWORDS COLUMN < index: rows where every term word, stemmed (see RBW_AWK_STEM),
# is a prefix of some word in COLUMN.
match_words() {
  awk -F'\t' -v tw="$1" -v col="$2" "$RBW_AWK_STEM"'
    BEGIN { n = split(tw, t, " ") }
    {
      m = split($col, w, " "); ok = 1
      for (i = 1; i <= n; i++) {
        s = stem(t[i])
        hit = 0
        for (j = 1; j <= m; j++) if (index(w[j], s) == 1) { hit = 1; break }
        if (!hit) { ok = 0; break }
      }
      if (ok) print
    }'
}

for term in "$@"; do
  words=$(rbw_words "$term" | tr '\n' ' ' | sed 's/ $//')
  [ -z "$words" ] && continue
  # shellcheck disable=SC2086  # split the words into positional parameters on purpose
  set -- $words
  camel=$1; pascal=$(printf '%s' "$1" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
  snake=$1; kebab=$1
  shift
  for w in "$@"; do
    cap=$(printf '%s' "$w" | awk '{print toupper(substr($0,1,1)) substr($0,2)}')
    camel="$camel$cap"; pascal="$pascal$cap"; snake="${snake}_$w"; kebab="$kebab-$w"
  done

  if [ $# -gt 0 ] || [ "$camel" != "$(printf '%s' "$term" | tr '[:upper:]' '[:lower:]')" ]; then
    printf '%s== %s%s  %s(%s %s %s %s)%s\n' "$RBW_BOLD" "$term" "$RBW_OFF" "$RBW_DIM" "$camel" "$pascal" "$snake" "$kebab" "$RBW_OFF"
  else
    printf '%s== %s%s\n' "$RBW_BOLD" "$term" "$RBW_OFF"
  fi

  match_words "$words" 3 < "$TMP/defs.idx" | awk -F'\t' '{print $2 "\t" $1}' | sort -u > "$TMP/hit.defs"
  match_words "$words" 2 < "$TMP/files.idx" | cut -f1 > "$TMP/hit.files"
  # Other identifiers that mention the term: parameters, properties, array keys, variables.
  first=$(printf '%s' "$words" | cut -d' ' -f1)
  stem=$(printf '%s\n' "$first" | awk "$RBW_AWK_STEM"'{ print stem($0) }')
  rbw_search "$stem" | awk -v stem="$stem" '
    {
      p1 = index($0, ":"); rest = substr($0, p1 + 1); p2 = index(rest, ":")
      loc = substr($0, 1, p1 - 1) ":" substr(rest, 1, p2 - 1); text = substr(rest, p2 + 1)
      while (match(text, /[A-Za-z_$][A-Za-z0-9_$]*/)) {
        tok = substr(text, RSTART, RLENGTH); text = substr(text, RSTART + RLENGTH); sub(/^[$]+/, "", tok)
        if (index(tolower(tok), stem) > 0) print tok "\t" loc
      }
    }' > "$TMP/mention.raw"
  cut -f1 "$TMP/mention.raw" | rbw_split_words > "$TMP/mention.words"
  paste "$TMP/mention.raw" "$TMP/mention.words" | match_words "$words" 3 \
    | awk -F'\t' 'FILENAME != "-" { seen[$2] = 1; next }
                   !($1 in seen) { n[$1]++; if (!($1 in at)) at[$1] = $2 }
                   END { for (k in n) printf "%d\t%s\t%s\n", n[k], k, at[k] }' "$TMP/hit.defs" - \
    | sort -t "$(printf '\t')" -k1,1nr -k2,2 > "$TMP/hit.mentions"
  nd=$(wc -l < "$TMP/hit.defs" | tr -d ' ')
  nm=$(wc -l < "$TMP/hit.mentions" | tr -d ' ')
  nf=$(wc -l < "$TMP/hit.files" | tr -d ' ')

  if [ "$nf" -gt 0 ]; then
    printf '  files (%s):\n' "$nf"
    head -n "$MAX_FILES" "$TMP/hit.files" | sed 's/^/    /'
    [ "$nf" -gt "$MAX_FILES" ] && printf '    %s... +%s more%s\n' "$RBW_DIM" $((nf - MAX_FILES)) "$RBW_OFF"
  fi
  if [ "$nd" -gt 0 ]; then
    printf '  definitions (%s):\n' "$nd"
    head -n "$MAX_DEFS" "$TMP/hit.defs" | awk -F'\t' '{printf "    %-48s %s\n", $1, $2}'
    [ "$nd" -gt "$MAX_DEFS" ] && printf '    %s... +%s more; use a more specific term%s\n' "$RBW_DIM" $((nd - MAX_DEFS)) "$RBW_OFF"
  fi
  if [ "$nm" -gt 0 ]; then
    printf '  other identifiers (%s):\n' "$nm"
    head -n "$MAX_MENTIONS" "$TMP/hit.mentions" | awk -F'\t' '{printf "    %-48s %s (%sx)\n", $2, $3, $1}'
    [ "$nm" -gt "$MAX_MENTIONS" ] && printf '    %s... +%s more%s\n' "$RBW_DIM" $((nm - MAX_MENTIONS)) "$RBW_OFF"
  fi
  if [ "$nf" -eq 0 ] && [ "$nd" -eq 0 ] && [ "$nm" -eq 0 ]; then
    if [ $# -gt 0 ]; then
      printf '  %snothing found; search the words separately, or try synonyms and translations%s\n' "$RBW_DIM" "$RBW_OFF"
    else
      printf '  %snothing found; try synonyms, translations or the verb instead of the noun%s\n' "$RBW_DIM" "$RBW_OFF"
    fi
  fi
done
exit 0
