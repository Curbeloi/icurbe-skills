# Eval results

Run on 2026-09-28 with Claude Code 2.1.266, `evals/run.sh`, one run per case and variant.
`baseline` = `systematic-debugging` only; `with_skill` = `systematic-debugging` + `reuse-before-write`.
Prompts are in Spanish and never name the skill.

| Model | Variant | Checks passed | Skill activated | Cost | Time |
|---|---|---|---|---|---|
| Claude Opus 5 (CLI default) | baseline | 19/19 | – | $1.90 | 253 s |
| Claude Opus 5 (CLI default) | with_skill | 19/19 | 5/5 | $2.64 | 337 s |
| Claude Haiku 4.5 | baseline | 17/19 | – | $0.48 | 205 s |
| Claude Haiku 4.5 | with_skill | 16/19 | 3/5 | $0.67 | 299 s |

## What this shows, and what it does not

- **Activation works on a strong model**: 5/5 with Opus 5, without naming the skill, on feature,
  bug and "make the tests green" prompts. On Haiku 4.5 it activated in 3/5 runs.
- **The fixtures are too easy to separate the variants on a strong model.** Opus 5 already reuses
  `formatCurrency`, fixes the parser instead of adding `?? 0` and fixes the code instead of the test
  without the skill, and it reports the pre-existing RUC duplicate in both variants. The differences
  with the skill are qualitative: an explicit reuse/extend/refactor/create decision and audit in
  every answer, and in case 4 it extended `RucValidator` without new files in 3/3 runs (baseline:
  a new `CedulaValidator.php` file in 1 of 2 runs).
- **On Haiku 4.5 the skill did not improve the checks.** In case 4 it found the duplicate during
  recon and the audit flagged the copied lines, but the model still created a third copy and
  called it "the same pattern" (SKILL.md now says explicitly that this is not a justification).
  The case 2 regression came from a run where the skill did not activate.
- **Overhead**: +39 % cost and +33 % time on Opus 5, +40 % and +46 % on Haiku 4.5, mostly the
  recon and the audit.

Found and fixed during these runs: answers came back in English to Spanish prompts (the summary
now follows the user's language), and name-based checks missed copied algorithms under new names
(`audit-diff.sh` now reports added lines that already exist elsewhere, with no dependency on jscpd).

Harder fixtures (larger repositories, where the helper to reuse is not in the first files an agent
opens) are the obvious next step to measure the skill's effect on strong models.
