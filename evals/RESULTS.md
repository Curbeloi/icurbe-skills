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

## 2026-09-29: duplicates and overlap on Haiku 4.5, three runs each

Claude Code 2.1.284, `evals/run.sh --only 4,9,11 --repeat 3 --model claude-haiku-4-5-20251001`:
18 runs, $2.69. These runs exposed a bug in the audit (below); case 4 `with_skill` was run three
more times with the fix, $0.50.

| Case | Variant | Checks passed | Skill activated | Kept a duplicate |
|---|---|---|---|---|
| 4: two RUC validators, add cédula (PHP) | baseline | 6/12 | – | 3/3 |
| | with_skill | 6/12 | 2/3 | 3/3 |
| | with_skill, audit fixed | 7/12 | 2/3 | 2/3 |
| 9: two phone normalizers, add suppliers (Python) | baseline | 7/12 | – | 2/3 |
| | with_skill | 10/12 | 2/3 | 2/3 |
| 11: an outbox already sends email (TypeScript) | baseline | 12/12 | – | 0/3 |
| | with_skill | 12/12 | 3/3 | 0/3 |

What the nine `with_skill` runs of cases 4 and 9 did with the duplicate, by what the audit showed:

| The audit showed the copy as | Runs | Copy removed |
|---|---|---|
| RED | 3 | 2 (extracted a shared validator; imported the existing normalizer) |
| YELLOW only | 3 | 0 ("it is the standard algorithm", "same pattern as the project") |
| skill not activated | 3 | 0 |

- **A RED copy item changes what the model does; a YELLOW one does not.** Twice the model fixed
  the copy after the RED and re-ran the audit, which no longer reported a copy. The third time it called the
  copy "intentional, consistent with the architecture" (the fixture has a comment saying `leads`
  copies the rule on purpose). Every YELLOW was justified away.
- **Bug found:** a copy with a few identical lines and a renamed rest was reported only as
  "4 added lines already exist" (YELLOW): the renamed-copy RED was dropped for pairs already
  reported as identical. Now there is one line per pair of files with the stronger signal, and
  identical lines around a renamed block longer than one window are RED. Both Haiku copies are
  regression tests (`tests/cases/4-haiku-*.sh`).
- Case 9: the final message named the existing copies in 3/3 `with_skill` runs (one of them
  without the skill activating) and in 0/3 baseline runs. Case 4: in no run, either variant.
- **Case 11 does not separate the variants on Haiku either**: all six runs queued the email
  through the outbox. A bigger repository, or a transport that looks like the obvious API, is
  needed to test feature overlap.
- One run saved the recon report as `RECON.md` in the repository; SKILL.md now says it goes in
  the reply.
- What this does not show: three runs per cell, activation at 2/3 on Haiku, one model.

## 2026-09-30: a RED copy is not a matter of justification

SKILL.md Phase 4 now gives a RED copy (sections 7 and 8) two ways out only, remove it or stop and
ask the user, and names the usual excuses ("the standard algorithm", "the project's pattern",
"intentional duplication") as not being ways out; the audit prints the same rule under its
summary when it reports a RED copy. Measured on the same two cases, `with_skill` only (the
baseline does not read the skill): `evals/run.sh --only 4,9 --variants with_skill --repeat 4
--model claude-haiku-4-5-20251001`, 8 runs, $1.29.

| Case | Checks passed | Skill activated | Kept a duplicate |
|---|---|---|---|
| 4: two RUC validators, add cédula (PHP) | 12/16 | 4/4 | 1/4 (the run that stopped to ask, copy still in the tree) |
| 9: two phone normalizers, add suppliers (Python) | 12/16 | 2/4 | 1/4 (the skill did not activate) |

What the six activated runs did:

| | Runs | Yesterday (6 activated runs) |
|---|---|---|
| Audit RED → removed the copy (extracted a shared validator, refactored `RucValidator`) | 2 | 2 |
| Audit RED → stopped and asked the user, copy in the tree | 1 | 0 |
| Audit RED or YELLOW → kept the copy with a justification | 0 | 4 |
| Asked the user before writing anything (Phase 3) | 2 | 0 |
| Reused the existing function, nothing to flag | 1 | 0 |

- **No activated run justified a copy.** The one that kept it did so to ask ("¿prefieres que
  refactorice ahora ... o que entregue como está con la duplicación documentada?"), which is what
  the rule asks for when the fix crosses modules. In `claude -p` nobody answers, so that run
  ends with the copy in place and the eval counts it as kept; with a person in the loop it is
  the right stop.
- Two runs asked before writing. One offered to unify (case 4, 4/4). The other (case 9)
  recommended copying "as `leads` does" and asked; the eval counts that as a failure because it
  neither implemented nor proposed unifying.
- Activation is still the weak point: 2/4 on case 9; the run that copied had not loaded the
  skill and described the paste as "using the same function that exists in customers".
- What this does not show: one model, four runs per case, and yesterday's RED runs had the
  audit bug for case 4 (so the "kept" column mixes YELLOW and RED). Whether the rule holds on
  Opus, or when the user answers "keep the copy", is not measured.
