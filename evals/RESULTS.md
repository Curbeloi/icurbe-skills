# Eval results

Run on 2026-09-28 with Claude Code 2.1.266, `evals/run.sh`, one run per case and variant (40 runs).
`baseline` = `systematic-debugging` only; `with_skill` = `systematic-debugging` + `reuse-before-write`.
Prompts are in Spanish and never name the skill. Cases 1-5 are TypeScript/PHP, 6-10 the same five
scenarios in Python.

| Model | Cases | Variant | Checks passed | Skill activated | Cost | Time |
|---|---|---|---|---|---|---|
| Claude Opus 5 (CLI default) | TS/PHP | baseline | 19/19 | – | $2.11 | 212 s |
| | | with_skill | 19/19 | 5/5 | $2.62 | 273 s |
| | Python | baseline | 20/20 | – | $1.96 | 358 s |
| | | with_skill | 20/20 | 5/5 | $2.32 | 310 s |
| Claude Haiku 4.5 | TS/PHP | baseline | 17/19 | – | $0.47 | 207 s |
| | | with_skill | 16/19 | 3/5 | $0.69 | 307 s |
| | Python | baseline | **13/20** | – | $0.37 | 175 s |
| | | with_skill | **18/20** | 3/5 | $0.55 | 265 s |

## What this shows

- **Python, Haiku 4.5: the skill changes the outcome.** Where it activated:
  - *Case 6*: without it, Haiku wrote its own `_business_days_between` weekday loop next to the
    existing `app/utils/dates.py:business_days_between`; with it, it imported and reused it.
  - *Case 7*: without it, Haiku added `if customer.email is None: return`, so no welcome was ever
    sent (0/4). With it, it found the real cause (the CSV has a UTF-8 BOM, fixed with `utf-8-sig`),
    although it also kept the guard.
  - *Case 9*: without it, Haiku pasted a third copy of `_normalize_phone` into suppliers; with it,
    it unified the two existing copies into `app/phone.py` and used that.
- **Activation**: 10/10 on Opus 5 without naming the skill; 6/10 on Haiku 4.5. When the skill does
  not activate, the run is effectively a baseline (Haiku case 4, TS/PHP).
- **On Opus 5 the fixtures do not separate the variants**: the model already reuses, fixes the
  source and leaves tests alone. With the skill every answer adds an explicit
  reuse/extend/refactor/create decision and an audit, in the user's language.
- **Haiku 4.5 on case 4 (PHP)** creates a third copy of the RUC check digit with or without the
  skill; in an earlier run the skill activated, the audit flagged the copied lines and the model
  still called it "the same pattern" (SKILL.md now says that is not a justification).
- **Overhead**: +21 % cost and +2 % time on Opus 5; +49 % cost and +50 % time on Haiku 4.5.

Fixed along the way: answers came back in English to Spanish prompts; name checks missed copied
algorithms under a new name (`audit-diff.sh` now reports added lines that already exist elsewhere,
no jscpd needed); a Python `except ...:` followed by `pass` on the next line was not reported as a
swallowed error; `contextlib.suppress` and `pylint: disable` count as suppressions.

Next step to measure the effect on strong models: larger fixtures, where the helper to reuse is not
in the first files an agent opens.

Added after these runs, not measured yet: case 11 (feature overlap in a ~30-file TypeScript
repository: an outbox with templates, opt-out and retries already sends email), `run.sh --repeat`,
and three audit signals aimed at overlapping features rather than copied names: new code that
calls the same uncommon operations as existing code, new calls into another module's internals,
and copies with renamed variables. On a hand-written third copy of the case 4 check digit with
every variable renamed, the audit now reports RED; before, it only showed a weak name match.
