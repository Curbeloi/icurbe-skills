# awk's string builtins (sub, gsub, substr...) are what every awk function calls; sharing them is
# not an overlap. Method calls with the same name (Python's re.sub) still count elsewhere.
FIXTURE=1-ts-reuse-format-currency
change() {
  mkdir -p scripts
  cat > scripts/trim.sh <<'SH'
awk '
  function trim(s) {
    sub(/^ +/, "", s); sub(/ +$/, "", s)
    gsub(/\t/, " ", s)
    return substr(s, 1, 80)
  }
  { print trim($0) }'
SH
  git add scripts && git -c user.name=t -c user.email=t@t commit -qm trim
  cat > scripts/slug.sh <<'SH'
awk '
  function slug(s) {
    s = tolower(s)
    gsub(/[^a-z0-9]+/, "-", s); sub(/^-/, "", s)
    return substr(s, 1, 40)
  }
  { print slug($0) }'
SH
}
expect() { expect_quiet_section 6; }
