---
name: reuse-before-write
description: >
  Mandatory guardrail before modifying existing code. ALWAYS use this skill
  when implementing a feature, fixing a bug, resolving an error, refactoring,
  or adding a function, class, module, utility, endpoint or dependency in a
  repository that already has code, even if the task looks small or urgent.
  This includes making failing tests pass, fixing a crash or an error message,
  and requests written in any language. Load it before the first edit.
  Forces a search for existing functionality to reuse (by name and by
  behaviour, so features do not overlap), root-cause identification before
  fixing, and a diff audit for duplication, overlap, symptom patches and dead
  code before declaring the task done.
---

# Reuse Before Write

Generating code is cheap; understanding a codebase is not. That asymmetry pushes agents into two
failures that compound over time:

1. **Duplication and overlap**: a new `dateToString` next to the existing `formatDate`, a
   `utils2.ts`, a second HTTP client, a dependency that does what an installed one already does,
   or a whole feature (a scheduler, a cache, a PDF renderer) that already exists under another name
   and in another shape.
2. **Symptom patches**: a `try/catch` that swallows the error, an `if (x == null) return 0`, a
   default value or a retry that hides corrupt state, a test edited until it passes.

Each one looks harmless in its own diff. Together they leave a codebase where every concept has
three implementations and every bug has two layers of camouflage. This skill puts two checkpoints
on every code change: **recon before writing** and **a diff audit before declaring done**.

## The iron rule

```
No new code before Phase 1 is done. No "done" before Phase 4 is done.
```

`<skill-dir>` below is the directory that contains this `SKILL.md`; the scripts need only `git`,
`grep` and bash (they use `rg` when available) and never touch the network.

Scale the effort to the task, but do not skip the phases:

- **Trivial change** (typo, rename in one file, config value, a one-line change to code you have
  already read): short Phase 1 (one search for the thing you are about to add or change) and Phase 4.
  No written recon report.
- **Everything else**: all four phases, with the recon report.

The skill must not paralyse you. When nothing reusable exists, record that in one line and build it.

## Phase 1: Recon (before writing anything)

The goal is to learn what already exists before deciding what is missing.

1. **Read the project's own map** if there is one: `CLAUDE.md`, `AGENTS.md`, `README*`,
   `ARCHITECTURE.md`, `CONTRIBUTING.md`, ADRs, specs. Projects often say where shared code lives
   and which helpers are canonical. That is the cheapest recon you will ever do.
2. **Extract 3 to 8 domain terms and verbs** from the task ("invoice", "tax", "calculate",
   "validate", "format date"). Add synonyms, and add translations when the codebase mixes
   languages (`factura`/`invoice`, `IVA`/`VAT`/`tax`).
3. **Search for them.** Run the bundled script from the repository root:
   ```bash
   bash <skill-dir>/scripts/find-similar.sh currency "format money" invoice total
   ```
   It expands camelCase / snake_case / kebab-case / PascalCase variants and searches file names
   and definitions (`function`, `def`, `fn`, `class`, `const x =`, `export`...). Treat hits as
   leads: open the promising ones and read what they actually do. Look *inside* them too: the
   logic you need is often embedded in a bigger function under another name (a check digit
   inside `validateTaxId`, a date format inside `renderReport`).
4. **Search by behaviour, not only by name.** Names are the weakest signal: the existing code that
   already does what you need often has a name you would never guess. Write down what you are
   about to build as observable behaviour: what it **produces** (a formatted label, a file, a
   computed number), what **effect** it has (sends a message, writes a row, caches, calls an
   API, validates an id) and which **primitives** it would use (`Intl.RelativeTimeFormat`,
   `fetch`, `preg_match`, `imagecopyresampled`, the DB client, the queue). Search for those
   primitives and effects:
   ```bash
   bash <skill-dir>/scripts/find-similar.sh RelativeTimeFormat fetch thumbnail
   ```
   Code that already uses the same primitives to produce the same output or effect is an
   overlap candidate whatever it is called. This applies to whole features too: a second job
   queue, another cache, another HTTP client, or new code that calls a low-level transport or
   driver directly instead of the module that wraps it, is the same failure at a larger scale.
5. **Check the usual homes of shared code**: `utils`, `helpers`, `lib`, `common`, `shared`, `core`,
   `services`, and the dependency manifest (`package.json`, `composer.json`, `Cargo.toml`,
   `requirements.txt`, `pyproject.toml`, `go.mod`). A library that is already installed beats a
   new one and beats hand-written code.
6. **Find the callers** of the code you are about to touch (`grep -rn "symbolName("`, or your
   editor's references). Callers tell you what must keep working and how wide the blast radius is.
7. **Write the recon report** in your reply to the user (never as a file in the repository), in
   the format of `references/recon-report-template.md`: what exists, where, whether it is
   reusable, what **overlaps** with the behaviour you are about to build, and what is really
   missing. Keep it short. It is a decision record, not an essay.

Why the report: writing "Found: `src/utils/money.ts:formatCurrency` (reusable: yes)" makes it
hard to then write a second currency formatter. The report is how the recon changes the code.

## Phase 2: Diagnosis (bugs and errors only)

A fix that does not name the cause is a guess, and guesses turn into patches.

- **If the `systematic-debugging` skill is installed, use it now** for the investigation, then
  come back here for Phases 3 and 4. Do not duplicate its process.
- If it is not installed:
  1. Reproduce the error (a failing test, a command, a request).
  2. Trace backwards from the symptom to where the wrong value or state is *created*, not where it
     *explodes*. The line that throws is usually a victim.
  3. State the root cause in one sentence ("The XML parser reads `<tax>` but the file has
     `<impuesto>`, so `rate` is null").
  4. Verify that sentence (a log, a test, a debugger) before you change anything.
- **Do not propose a fix without a root cause.** If three fix attempts fail, stop. That pattern
  means the design is wrong or your model of it is. Explain what you found to the user and question
  the approach together instead of trying a fourth patch.

A guard at the crash site is legitimate only **in addition** to fixing the source, and only when
the input can legitimately be absent (user input, an external API). Say which case applies.

## Phase 3: Explicit decision

First answer one question: **does anything in the repository already produce this output or
this effect, for any caller?** If yes, that is what you reuse, extend or unify, even when its
code looks nothing like what you would write. Two features that do the same thing in different
ways are worse than two copies of the same code: nobody notices they are duplicates, and they
drift apart silently.

Then pick exactly one option, in this order of preference, and justify it in one line:

1. **Reuse** what exists as-is.
2. **Extend** what exists (a parameter, a new case, an overload) without breaking its callers.
3. **Refactor**: unify the existing duplicates first, then use the unified version.
4. **Create new**: only when 1 to 3 do not apply. Say why ("no date handling exists anywhere; the
   project has no date library").

The order exists because every new symbol is a long-term cost: someone has to find it, keep it
in sync with its siblings and eventually delete one of them.

"Create new" is wrong when the new code would re-implement logic that already exists **inside**
another function, even under a different name: extract that logic into its own function, make the
old caller use it, and build on it (that is *extend*, or *refactor*). A new class whose body is
the old loop with variables renamed is a copy, not new code.

If the decision is **refactor** or **create new** and it touches more than one module (or public
API, or shared code), **ask the user before implementing**. Those changes outlive the task and the
user may know why the duplicates exist.

When you find duplicates you are not going to unify now, still **report them** to the user and
build on the better of the two. Do not add a third.

## Phase 4: Diff audit (before saying "done")

Run the audit from the repository root:

```bash
bash <skill-dir>/scripts/audit-diff.sh          # working tree + untracked vs HEAD
bash <skill-dir>/scripts/audit-diff.sh main     # or against a base ref
```

Both scripts skip dependencies, build output and test data (`fixtures/`, `testdata/`,
`__snapshots__/`), plus any path listed in `.reuse-before-write-ignore` at the repository root
or in `RBW_EXCLUDE` (a prefix like `legacy/` or a glob like `*.pb.go`).

It lists new files; new definitions that repeat within the change, share a name with existing
code, or look like it (`(weak)` = one word in common); new symbols nothing references; added
`try/catch`, fallbacks and suppressions; touched tests (removed assertions, skips); manifest
changes; new definitions that call the same operations as an existing one (possible functional
overlap); added code lines that already exist elsewhere, verbatim or with only the names changed;
and copy-paste blocks when `jscpd` is installed. **RED** marks what is almost always a
problem (swallowed errors, suppressions, weakened or skipped tests, cloned blocks); **YELLOW** marks
what needs a one-line justification. The script only informs and never fails, and every match is
a heuristic: read the flagged code before you act on it. A clean audit does not prove there is no
overlap (two implementations can share no name, no line and no operation), so the first
checklist item is yours to answer. Then answer this checklist honestly:

- [ ] **Functional overlap**: does anything you added do what another part of the code already
      does, even with different code, names or libraries? If yes: reuse, extend or unify. If you
      keep both, say so in the final summary and say why.
- [ ] **New files**: is each one justified by the Phase 3 decision?
- [ ] **New functions/classes**: does any have a name or signature similar to an existing one?
- [ ] **Copied logic**: does any new body repeat a loop, formula or regex from code you read in
      Phase 1? Compare bodies, not names; the audit lists copied lines, including renamed copies.
- [ ] **Fallbacks**: did you add `try/catch`, `except`, `??`, `|| default`, `unwrap_or`, default
      values or special-case `if`s? For each: does it fix the cause, or hide the symptom?
- [ ] **Tests**: did you modify a test? If so, was the test wrong (say why), or was it adjusted
      to pass? Changing an assertion to match buggy output is not a fix.
- [ ] **Dead code**: did you leave the old version in place next to the new one?
- [ ] **Dependencies**: did you add one that duplicates an installed one?
- [ ] **Size**: is the diff the minimum needed for the task?

If any answer is a problem, fix it before delivering. "It follows the same pattern" does not
justify copied lines or a near-duplicate name: extract the shared code, or tell the user in the
final summary that you copied it and why. See `references/anti-patterns.md` for
before/after examples of each failure in PHP, TypeScript and Rust.

## Final output to the user

End with a short summary and no filler, **in the language the user writes in** (this skill is in
English, the user may not be; translate the labels too):

```
Root cause: <one sentence, bugs only>
Decision: reuse | extend | refactor | create: <one-line justification>
Audit: <"clean", or the flagged items and what you did about them>
```

## Red flags: stop and go back to Phase 1

- You are about to create a file whose name ends in `2`, `new`, `v2`, `_fixed`, `helper`, `utils`
  in a project that already has one.
- You are writing a function whose name you have not searched for.
- You are building something whose output or effect you have not searched for (only its name).
- You are adding `npm install` / `composer require` / `cargo add` without checking the manifest.
- You are wrapping a call in `try/catch` because "it sometimes fails".
- You are editing a test's expected value right after the test failed.
- You are on your third fix attempt for the same error.
