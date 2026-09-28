#!/usr/bin/env bash
# Runs the reuse-before-write evals with Claude Code in headless mode, with and without the skill.
#
#   evals/run.sh [--only 1,3] [--variants with_skill,baseline] [--model <id>] [--out <dir>]
#                [--repeat N] [--jobs J]
#
# For each case it copies evals/fixtures/<fixture> into <out>/<case>/<variant>/run-<k>/repo, commits it,
# installs the skills of the variant into the repo's .claude/skills/, runs `claude -p` with the
# prompt (the skill is never named) and then the programmatic checks in evals/checks/<id>.sh.
#   baseline   = systematic-debugging only (the recommended companion skill)
#   with_skill = systematic-debugging + reuse-before-write
# User-level settings, skills and MCP servers are not loaded (--setting-sources project,local),
# so your own ~/.claude setup does not leak into the results. Results go outside the repository
# (default $TMPDIR/reuse-before-write-evals/<timestamp>) so no parent CLAUDE.md is picked up.
# --repeat N runs every case and variant N times (default 1), so one lucky or unlucky run does
# not decide the result; the summary aggregates them. --jobs J caps parallel runs (default 6).
#
# Needs: claude, git, node >= 23 (runs .ts tests natively), php >= 8.1, python >= 3.10, and systematic-debugging
# (npx skills add obra/superpowers --skill systematic-debugging -g, or set SYSTEMATIC_DEBUGGING).
# Costs real API usage: 2 x N runs per case, capped by --max-budget-usd per run (default 3).

set -u
ROOT=$(cd "$(dirname "$0")/.." && pwd)
SKILL="$ROOT/skills/reuse-before-write"
EVALS="$SKILL/evals/evals.json"
SD="${SYSTEMATIC_DEBUGGING:-$HOME/.claude/skills/systematic-debugging}"
ONLY=""; VARIANTS="with_skill,baseline"; MODEL=""; OUT="${TMPDIR:-/tmp}/reuse-before-write-evals/$(date +%Y%m%d-%H%M%S)"
BUDGET="${BUDGET:-3}"; REPEAT=1; JOBS=6

while [ $# -gt 0 ]; do
  case "$1" in
    --only) ONLY=$2; shift 2 ;;
    --variants) VARIANTS=$2; shift 2 ;;
    --model) MODEL=$2; shift 2 ;;
    --out) OUT=$2; shift 2 ;;
    --repeat) REPEAT=$2; shift 2 ;;
    --jobs) JOBS=$2; shift 2 ;;
    -h|--help) sed -n '2,20p' "$0" | sed 's/^# \{0,1\}//'; exit 0 ;;
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

run_case() {  # id name fixture prompt variant run
  local id=$1 name=$2 fixture=$3 prompt=$4 variant=$5 run=$6
  local dir="$OUT/eval-$id-$name/$variant/run-$run" repo
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
  local pass total act cost
  pass=$(grep -c '^PASS' "$dir/checks.tsv"); total=$(grep -cE '^(PASS|FAIL)' "$dir/checks.tsv")
  act=$(node -e 'console.log(require(process.argv[1]).activated ? "yes" : "no")' "$dir/run.json")
  cost=$(node -e 'console.log(require(process.argv[1]).cost_usd.toFixed(2))' "$dir/run.json")
  printf '%s\t%s\t%s\t%s\t%s/%s\t%s\t%s\t%ss\n' "$id" "$name" "$variant" "$run" "$pass" "$total" "$act" "$cost" "$((end - start))" | tee -a "$OUT/summary.tsv"
}

printf 'id\tcase\tvariant\trun\tchecks\tskill_activated\tcost_usd\ttime\n' > "$OUT/summary.tsv"
while IFS="$(printf '\t')" read -r id name fixture prompt; do
  if [ -n "$ONLY" ] && ! printf ',%s,' "$ONLY" | grep -q ",$id,"; then continue; fi
  for variant in $(printf '%s' "$VARIANTS" | tr ',' ' '); do
    k=1
    while [ "$k" -le "$REPEAT" ]; do
      # bash 3.2 has no wait -n: poll until a slot frees up.
      while [ "$(jobs -rp | wc -l | tr -d ' ')" -ge "$JOBS" ]; do sleep 2; done
      run_case "$id" "$name" "$fixture" "$prompt" "$variant" "$k" &
      k=$((k + 1))
    done
  done
done < "$OUT/cases.tsv"
wait

# One line per case and variant: checks passed over all runs, activation rate, mean cost and time.
awk -F'\t' 'NR > 1 {
    key = $1 "\t" $2 "\t" $3; if (!(key in n)) order[++m] = key
    n[key]++; split($5, c, "/"); pass[key] += c[1]; tot[key] += c[2]
    act[key] += ($6 == "yes"); cost[key] += $7; t = $8; sub(/s$/, "", t); time[key] += t
  }
  END {
    print "id\tcase\tvariant\truns\tchecks\tskill_activated\tmean_cost_usd\tmean_time"
    for (i = 1; i <= m; i++) { k = order[i]
      printf "%s\t%d\t%d/%d\t%d/%d\t%.2f\t%ds\n", k, n[k], pass[k], tot[k], act[k], n[k], cost[k] / n[k], time[k] / n[k] }
  }' "$OUT/summary.tsv" | sort -t "$(printf '\t')" -k1,1n -k3,3 > "$OUT/aggregate.tsv"

echo; echo "Results in $OUT"; column -t -s "$(printf '\t')" "$OUT/aggregate.tsv"
