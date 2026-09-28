# shellcheck shell=bash
# shellcheck disable=SC2034  # the variables defined here are used by the scripts that source it
# Shared helpers for find-similar.sh and audit-diff.sh. Sourced, never executed.
# Portable to bash 3.2 (macOS): no associative arrays, no ${var,,}, no mapfile.
# Needs only git and grep; uses ripgrep when it is installed. Never touches the network.

# Agent config dirs (.claude, .agents...) hold skills and prompts, not project code to reuse.
RBW_EXCLUDE_DIRS="node_modules vendor target dist build .git .next .nuxt out coverage __pycache__ .venv venv .claude .agents .codex .opencode .cursor"

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

# True when the path lies inside one of the excluded directories.
rbw_is_excluded() {
  local d
  for d in $RBW_EXCLUDE_DIRS; do
    case "/$1" in */"$d"/*) return 0 ;; esac
  done
  return 1
}

# Every tracked or untracked-but-not-ignored file that exists on disk (or a find walk outside
# git), one per line, relative to the current directory, without excluded directories. Tracked
# files deleted in the working tree are left out: awk aborts a whole batch on a missing file.
rbw_list_files() {
  local prune d
  if rbw_in_git; then
    git ls-files -co --exclude-standard 2>/dev/null
  else
    prune=''
    for d in $RBW_EXCLUDE_DIRS; do prune="$prune -name $d -o"; done
    # shellcheck disable=SC2086
    find . \( ${prune% -o} \) -prune -o -type f -print 2>/dev/null | sed 's|^\./||'
  fi | while IFS= read -r f; do [ -f "$f" ] && ! rbw_is_excluded "$f" && printf '%s\n' "$f"; done
}

# rbw_search REGEX: case-insensitive POSIX ERE search over the repository.
# Prints path:line:text. Uses rg, then git grep, then grep -r.
rbw_search() {
  local re="$1" d globs
  if command -v rg >/dev/null 2>&1; then
    globs=''
    for d in $RBW_EXCLUDE_DIRS; do globs="$globs -g !$d/"; done
    # shellcheck disable=SC2086
    rg --no-heading --line-number --ignore-case --no-messages $globs -e "$re" . 2>/dev/null \
      | sed 's|^\./||'
  elif rbw_in_git; then
    set --
    for d in $RBW_EXCLUDE_DIRS; do set -- "$@" ":(exclude,glob)**/$d/**"; done
    git grep --untracked -I -n -i -E -e "$re" -- . "$@" 2>/dev/null
  else
    set --
    for d in $RBW_EXCLUDE_DIRS; do set -- "$@" "--exclude-dir=$d"; done
    grep -rIn -i -E "$@" -e "$re" . 2>/dev/null | sed 's|^\./||'
  fi
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
