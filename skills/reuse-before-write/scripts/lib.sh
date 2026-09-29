# shellcheck shell=bash
# shellcheck disable=SC2034  # the variables defined here are used by the scripts that source it
# Shared helpers for find-similar.sh and audit-diff.sh. Sourced, never executed.
# Portable to bash 3.2 (macOS): no associative arrays, no ${var,,}, no mapfile.
# Needs only git and grep; uses ripgrep when it is installed. Never touches the network.

# Agent config dirs (.claude, .agents...) hold skills and prompts, not project code to reuse.
# Test data dirs (fixtures, testdata, snapshots) hold duplicates and bad code on purpose.
RBW_EXCLUDE_DIRS="node_modules vendor target dist build .git .next .nuxt out coverage __pycache__ .venv venv .claude .agents .codex .opencode .cursor fixtures __fixtures__ testdata __snapshots__"

# Identifier characters shared by every language we look at ($ for JS/PHP).
RBW_ID='[A-Za-z_$][A-Za-z0-9_$]*'

rbw_color() {
  if [ -t 1 ] && [ -z "${NO_COLOR:-}" ]; then
    RBW_RED=$(printf '\033[31m'); RBW_YEL=$(printf '\033[33m'); RBW_GRN=$(printf '\033[32m')
    RBW_BOLD=$(printf '\033[1m'); RBW_DIM=$(printf '\033[2m'); RBW_OFF=$(printf '\033[0m')
  else
    RBW_RED=''; RBW_YEL=''; RBW_GRN=''; RBW_BOLD=''; RBW_DIM=''; RBW_OFF=''
  fi
}

rbw_in_git() { git rev-parse --is-inside-work-tree >/dev/null 2>&1; }

# Project-specific paths to leave out, from the RBW_EXCLUDE variable (space separated) and from
# .reuse-before-write-ignore in the current directory (the repository root; # starts a comment).
# A pattern with a "/" is anchored at the root: "legacy/" or "src/generated" is that tree,
# "docs/**/*.md" a glob. Without a "/" it matches a file or directory name at any depth: "*.pb.go".
rbw_exclude_patterns() {
  {
    # Split on spaces with tr, not by the shell: the shell would expand "*.gen.ts" into files.
    printf '%s\n' "${RBW_EXCLUDE:-}" | tr ' ' '\n'
    [ -f .reuse-before-write-ignore ] && cat .reuse-before-write-ignore
  } | sed 's/#.*//; s/^[[:space:]]*//; s/[[:space:]]*$//' | grep -v '^$'
}

# rbw_filter_paths [WHERE]: drops the input lines whose path is excluded (RBW_EXCLUDE_DIRS or
# rbw_exclude_patterns). WHERE says where the path is: the whole line (default), ":" for the
# text before the first colon (path:line:text), or a number for that tab-separated field.
rbw_filter_paths() {
  # shellcheck disable=SC2016  # the $ are awk fields, not shell expansions
  awk -v where="${1:-line}" -v dirs="$RBW_EXCLUDE_DIRS" -v pats="$(rbw_exclude_patterns | tr '\n' ' ')" '
    function glob2re(g,   r, i, c) {
      r = ""
      for (i = 1; i <= length(g); i++) {
        c = substr(g, i, 1)
        if (substr(g, i, 3) == "**/") { r = r "(.*/)?"; i += 2 }
        else if (substr(g, i, 2) == "**") { r = r ".*"; i++ }
        else if (c == "*") r = r "[^/]*"
        else if (c == "?") r = r "[^/]"
        else if (index(".+()|^$[]{}\\", c)) r = r "\\" c
        else r = r c
      }
      if (index(g, "/") == 0) return "(^|/)" r "(/|$)"
      sub(/^\//, "", r)
      return "^" r (g ~ /\/$/ ? "" : "(/|$)")
    }
    BEGIN {
      nd = split(dirs, d, " "); for (i = 1; i <= nd; i++) d[i] = "/" d[i] "/"
      np = split(pats, p, " "); for (i = 1; i <= np; i++) re[i] = glob2re(p[i])
    }
    {
      if (where == "line") path = $0
      else if (where == ":") path = substr($0, 1, index($0, ":") - 1)
      else { split($0, f, "\t"); path = f[where + 0] }
      for (i = 1; i <= nd; i++) if (index("/" path, d[i])) next
      for (i = 1; i <= np; i++) if (path ~ re[i]) next
      print
    }'
}

# Every tracked or untracked-but-not-ignored file that exists on disk (or a find walk outside
# git), one per line, relative to the current directory, without excluded paths. Tracked files
# deleted in the working tree are left out: awk aborts a whole batch on a missing file.
rbw_list_files() {
  local prune d
  if rbw_in_git; then
    awk 'FILENAME == ARGV[1] { gone[$0] = 1; next } !($0 in gone) && !seen[$0]++' \
      <(git ls-files -d 2>/dev/null) <(git ls-files -co --exclude-standard 2>/dev/null)
  else
    prune=''
    for d in $RBW_EXCLUDE_DIRS; do prune="$prune -name $d -o"; done
    # shellcheck disable=SC2086
    find . \( ${prune% -o} \) -prune -o -type f -print 2>/dev/null | sed 's|^\./||'
  fi | rbw_filter_paths
}

rbw_has_rg() { command -v rg >/dev/null 2>&1; }

# rbw_rg ARGS...: ripgrep over the repository, skipping the excluded directories; paths are
# printed without the leading "./".
rbw_rg() {
  local d globs=''
  for d in $RBW_EXCLUDE_DIRS; do globs="$globs -g !$d/"; done
  # shellcheck disable=SC2086
  rg --no-heading --no-messages $globs "$@" . 2>/dev/null | sed 's|^\./||'
}

# rbw_search REGEX: case-insensitive POSIX ERE search over the repository, without excluded
# paths. Prints path:line:text. Uses rg, then git grep, then grep -r.
rbw_search() {
  local re="$1" d
  if rbw_has_rg; then
    rbw_rg --line-number --ignore-case -e "$re"
  elif rbw_in_git; then
    set --
    for d in $RBW_EXCLUDE_DIRS; do set -- "$@" ":(exclude,glob)**/$d/**"; done
    git grep --untracked -I -n -i -E -e "$re" -- . "$@" 2>/dev/null
  else
    set --
    for d in $RBW_EXCLUDE_DIRS; do set -- "$@" "--exclude-dir=$d"; done
    grep -rIn -i -E "$@" -e "$re" . 2>/dev/null | sed 's|^\./||'
  fi | rbw_filter_paths :
}

# rbw_count_refs WORDS_FILE: how often each word of WORDS_FILE (one per line) appears in the
# repository as a whole word, ignoring case, as "count<TAB>word" with the word in lowercase.
# With rg, one search for all the words. Without it, one rbw_search per word up to 20 words
# (about 0.2 s each on 3,000 files), else one awk pass that splits every line into words (about
# 3 s whatever the number of words; git grep -F -w -i -f is slower than both).
rbw_count_refs() {
  local words="$1" w
  if rbw_has_rg; then
    rbw_rg --no-line-number --with-filename --only-matching --ignore-case --word-regexp --fixed-strings -f "$words" \
      | rbw_filter_paths : | awk '{ print tolower(substr($0, index($0, ":") + 1)) }'
  elif [ "$(wc -l < "$words")" -le 20 ]; then
    while IFS= read -r w; do
      rbw_search "(^|[^A-Za-z0-9_\$])$w([^A-Za-z0-9_\$]|\$)" | awk -v w="$w" '{ print tolower(w) }'
    done < "$words"
  else
    # xargs may split the file list; every awk call gets WORDS_FILE first. LC_ALL=C: binary-safe.
    # shellcheck disable=SC2016  # the $ are awk fields, not shell expansions
    rbw_list_files | tr '\n' '\0' | LC_ALL=C xargs -0 awk '
      FILENAME == ARGV[1] { want[tolower($0)] = 1; next }
      FNR == 1 { binary = (FILENAME ~ /\.(png|jpe?g|gif|ico|webp|pdf|zip|t?gz|woff2?|ttf|otf|eot|mp[34]|wasm|jar|class|so|dylib|dll|exe)$/) }
      binary { next }
      { n = split(tolower($0), w, /[^a-z0-9_]+/); for (i = 1; i <= n; i++) if (w[i] in want) print w[i] }' "$words" 2>/dev/null
  fi | awk '{ n[$0]++ } END { for (w in n) print n[w] "\t" w }'
}

# Reads path:line:text records on stdin and prints "identifier<TAB>path:line" for every line
# that defines a function, class, type, method or function-valued constant.
# Covers PHP, JS/TS, Python, Ruby, Rust, Go, Java/C#/Kotlin well enough to find neighbours.
rbw_extract_defs() {
  awk '
    function emit(id) {
      if (id ~ /^(if|for|while|switch|return|new|await|catch|function|constructor|else|do|in|of|that|the|this|which|is|a|an|and|or|to|with|as|it|be|was|are|we|you|not)$/) return
      printf "%s\t%s:%s\n", id, path, lno
    }
    {
      # path:line:text; the text may itself contain colons.
      p1 = index($0, ":"); if (p1 == 0) next
      rest = substr($0, p1 + 1); p2 = index(rest, ":"); if (p2 == 0) next
      path = substr($0, 1, p1 - 1); lno = substr(rest, 1, p2 - 1); text = substr(rest, p2 + 1)
      if (lno !~ /^[0-9]+$/) next
      # Comment lines are prose ("the type that ..."), not definitions. #[ and #! are code.
      if (text ~ /^[[:space:]]*(\/\/|\/\*|\*|#([^[!]|$)|<!--|--[[:space:]])/) next
      id = ""
      if (match(text, /func[[:space:]]*\([^)]*\)[[:space:]]*[A-Za-z_][A-Za-z0-9_]*/)) {
        # Go method receiver: func (r *T) Name(
        s = substr(text, RSTART, RLENGTH); sub(/.*[[:space:])]/, "", s); id = s
      } else if (match(text, /(^|[^A-Za-z0-9_$.])(function|def|fn|class|interface|trait|struct|enum|type|func|module|record)[[:space:]]+[A-Za-z_$][A-Za-z0-9_$]*/)) {
        s = substr(text, RSTART, RLENGTH); sub(/.*[[:space:]]/, "", s); id = s
      } else if (match(text, /(^|[^A-Za-z0-9_$.])(const|let|var)[[:space:]]+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(:[^=]*)?=[[:space:]]*(async[[:space:]]+)?(function|\(|[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*=>)/)) {
        s = substr(text, RSTART, RLENGTH); sub(/^[^A-Za-z_$]*(const|let|var)[[:space:]]+/, "", s)
        match(s, /^[A-Za-z_$][A-Za-z0-9_$]*/); id = substr(s, 1, RLENGTH)
      } else if (match(text, /^[[:space:]]*((public|private|protected|static|async|readonly|override|abstract|final)[[:space:]]+)+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(<[^>]*>)?\(/)) {
        s = substr(text, RSTART, RLENGTH); sub(/[[:space:]]*(<[^>]*>)?\($/, "", s); sub(/.*[[:space:]]/, "", s); id = s
      }
      if (id != "") emit(id)
    }'
}

# The POSIX ERE (for rbw_search) that finds candidate definition lines, cheaply, before
# rbw_extract_defs does the precise parsing.
RBW_DEF_RE='(function|def|fn|class|interface|trait|struct|enum|type|func|module|record)[[:space:]]+[A-Za-z_$]|(const|let|var)[[:space:]]+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(:[^=]*)?=[[:space:]]*(async[[:space:]]+)?(function|\(|[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*=>)|^[[:space:]]*((public|private|protected|static|async|readonly|override|abstract|final)[[:space:]]+)+[A-Za-z_$][A-Za-z0-9_$]*[[:space:]]*(<[^>]*>)?\('

# rbw_split_words: filter that turns each line of names into lowercase words.
# "formatCurrency" -> "format currency", "IVACalculator" -> "iva calculator", "$ruc_valido" -> " ruc valido"
rbw_split_words() {
  sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/([A-Z]+)([A-Z][a-z])/\1 \2/g; s/[^A-Za-z0-9]+/ /g' | tr '[:upper:]' '[:lower:]'
}

# awk function stem(w): the word itself up to 5 chars, else the word minus 3 chars (at least 5).
# Used as a prefix, it lets validation~validate, invoice~invoices, calcular~calculate match.
RBW_AWK_STEM='function stem(w,  l) { l = length(w); return (l <= 5) ? w : substr(w, 1, (l - 3 < 5) ? 5 : l - 3) }'

# rbw_words NAME: splits an identifier or phrase into lowercase words, one per line.
# formatCurrency, format_currency, format-currency, "format currency" -> format, currency
rbw_words() {
  printf '%s\n' "$1" \
    | sed -E 's/([a-z0-9])([A-Z])/\1 \2/g; s/([A-Z]+)([A-Z][a-z])/\1 \2/g; s/[^A-Za-z0-9]+/ /g' \
    | tr '[:upper:]' '[:lower:]' | tr ' ' '\n' | sed '/^$/d'
}
