#!/usr/bin/env bash
# Runs the reuse-before-write evals with Claude Code in headless mode, with and without the skill.
#
#   evals/run.sh [--only 1,3] [--variants with_skill,baseline] [--model <id>] [--out <dir>]
#
# For each case it copies evals/fixtures/<fixture> into <out>/<case>/<variant>/repo, commits it,
# installs the skills of the variant into the repo's .claude/skills/, runs `claude -p` with the
# prompt (the skill is never named) and then the programmatic checks in evals/checks/<id>.sh.
#   baseline   = systematic-debugging only (the recommended companion skill)
#   with_skill = systematic-debugging + reuse-before-write
# User-level settings, skills and MCP servers are not loaded (--setting-sources project,local),
# so your own ~/.claude setup does not leak into the results. Results go outside the repository
# (default $TMPDIR/reuse-before-write-evals/<timestamp>) so no parent CLAUDE.md is picked up.
# All runs start in parallel.
#
# Needs: claude, git, node >= 23 (runs .ts tests natively), php >= 8.1, and systematic-debugging
# (npx skills add obra/superpowers --skill systematic-debugging -g, or set SYSTEMATIC_DEBUGGING).
# Costs real API usage: 2 runs per case, capped by --max-budget-usd per run (default 3).

set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/reuse-before-write"
EVALS="$SKILL/evals/evals.json"
SD="${SYSTEMATIC_DEBUGGING:-$HOME/.claude/skills/systematic-debugging}"
ONLY=""; VARIANTS="with_skill,baseline"; MODEL=""; OUT="${TMPDIR:-/tmp}/reuse-before-write-evals/$(date +%Y%m%d-%H%M%S)"
BUDGET="${BUDGET:-3}"

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY=$2; shift 2 ;;
    --variants) VARIANTS=$2; shift 2 ;;
    --model) MODEL=$2; shift 2 ;;
    --out) OUT=$2; shift 2 ;;
    -h|--help) sed -n '2,17p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
    *) echo "unknown option $1"; exit 2 ;;
  esac
done

[ -f "$SD/SKILL.md" ] || { echo "systematic-debugging not found at $SD"; exit 2; }
command -v claude >/dev/null || { echo "claude CLI not found"; exit 2; }
mkdir -p "$OUT"

# id<TAB>name<TAB>fixture<TAB>prompt, one line per eval.
node -e '
  const e = require(process.argv[1]).evals;
  for (const x of e) console.log([x.id, x.name, x.fixture, x.prompt].join("\t"));
' "$EVALS" > "$OUT/cases.tsv"

run_case() {  # id name fixture prompt variant
  local id=$1 name=$2 fixture=$3 prompt=$4 variant=$5
  local dir="$OUT/eval-$id-$name/$variant" repo
  repo="$dir/repo"
  rm -rf "$dir"; mkdir -p "$dir"
  cp -R "$ROOT/evals/fixtures/$fixture" "$repo"
  mkdir -p "$repo/.claude/skills"
  cp -R "$SD" "$repo/.claude/skills/systematic-debugging"
  [ "$variant" = with_skill ] && cp -R "$SKILL" "$repo/.claude/skills/reuse-before-write" \
    && rm -rf "$repo/.claude/skills/reuse-before-write/evals"
  (cd "$repo" && git init -q && git add -A \
    && git -c user.name=eval -c user.email=eval@localhost commit -qm fixture)
  # The agent may commit its own work; always compare against the fixture commit.
  local base_ref
  base_ref=$(git -C "$repo" rev-parse HEAD)

  local start end
  start=$(date +%s)
  # shellcheck disable=SC2086
  (cd "$repo" && claude -p "$prompt" \
      --setting-sources project,local --strict-mcp-config --no-session-persistence \
      --permission-mode acceptEdits --allowedTools "Bash Read Edit Write Glob Grep Skill" \
      --output-format stream-json --verbose --max-budget-usd "$BUDGET" \
      ${MODEL:+--model "$MODEL"} < /dev/null > "$dir/transcript.jsonl" 2> "$dir/stderr.log")
  end=$(date +%s)

  node -e '
    const fs = require("fs"); const lines = fs.readFileSync(process.argv[1], "utf8").split("\n").filter(Boolean);
    let result = "", cost = 0, turns = 0, activated = false, tokens = 0;
    for (const l of lines) {
      let m; try { m = JSON.parse(l); } catch { continue; }
      if (m.type === "assistant") for (const c of m.message?.content ?? []) {
        if (c.type !== "tool_use") continue;
        const s = JSON.stringify(c.input ?? {});
        if (c.name === "Skill" && s.includes("reuse-before-write")) activated = true;
        if (c.name === "Read" && s.includes("reuse-before-write/SKILL.md")) activated = true;
      }
      if (m.type === "result") {
        result = m.result ?? ""; cost = m.total_cost_usd ?? 0; turns = m.num_turns ?? 0;
        const u = m.usage ?? {}; tokens = (u.input_tokens ?? 0) + (u.output_tokens ?? 0) + (u.cache_read_input_tokens ?? 0) + (u.cache_creation_input_tokens ?? 0);
      }
    }
    fs.writeFileSync(process.argv[2], result + "\n");
    fs.writeFileSync(process.argv[3], JSON.stringify({ activated, cost_usd: cost, turns, total_tokens: tokens, total_duration_seconds: Number(process.argv[4]) }, null, 2) + "\n");
  ' "$dir/transcript.jsonl" "$dir/final.md" "$dir/run.json" "$((end - start))"

  (cd "$repo" && git add -A -N . && git diff "$base_ref" -- . ':(exclude).claude' > "$dir/diff.patch")
  (cd "$repo" && FINAL="$dir/final.md" BASE_REF="$base_ref" bash "$ROOT/evals/checks/$id.sh" > "$dir/checks.tsv" 2>&1)
  local pass total act
  pass=$(grep -c '^PASS' "$dir/checks.tsv"); total=$(grep -cE '^(PASS|FAIL)' "$dir/checks.tsv")
  act=$(node -e 'console.log(require(process.argv[1]).activated ? "yes" : "no")' "$dir/run.json")
  printf '%s\t%s\t%s\t%s/%s\t%s\t%ss\n' "$id" "$name" "$variant" "$pass" "$total" "$act" "$((end - start))" | tee -a "$OUT/summary.tsv"
}

printf 'id\tcase\tvariant\tchecks\tskill_activated\ttime\n' > "$OUT/summary.tsv"
while IFS="$(printf '\t')" read -r id name fixture prompt; do
  if [ -n "$ONLY" ] && ! printf ',%s,' "$ONLY" | grep -q ",$id,"; then continue; fi
  for variant in $(printf '%s' "$VARIANTS" | tr ',' ' '); do
    run_case "$id" "$name" "$fixture" "$prompt" "$variant" &
  done
done < "$OUT/cases.tsv"
wait

echo; echo "Results in $OUT"; column -t -s "$(printf '\t')" "$OUT/summary.tsv"
