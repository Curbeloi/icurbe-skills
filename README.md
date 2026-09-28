# skills

Agent Skills for coding agents (Claude Code, OpenCode, Codex and any harness that supports the
[Agent Skills](https://agentskills.io) format), installable with [`npx skills`](https://skills.sh).

[English](#english) · [Español](#español)

---

## English

### `reuse-before-write`

A lightweight guardrail that runs on **every** code change, feature or bug fix, with two
checkpoints:

1. **Recon before writing**: search the repository for what already exists (helpers, services,
   installed libraries, callers) and decide explicitly: *reuse → extend → refactor → create*.
2. **Diff audit before "done"**: new files, new functions with similar existing names, added
   `try/catch` / `??` / `unwrap_or` / suppressions, tests that were edited, new dependencies and
   copy-pasted blocks.

**The problem it solves.** Generating code is cheaper than understanding it, so agents tend to
duplicate functionality under a new name (`formatDate` next to `dateToString`, `utils2.ts`, a second
HTTP client) and to patch symptoms (a `catch` that swallows the error, `?? 0`, a test edited until
it passes). Each diff looks fine on its own; together they rot the codebase.

### Install

It complements [`systematic-debugging`](https://github.com/obra/superpowers/tree/main/skills/systematic-debugging)
from obra/superpowers. Install both, in this order:

```bash
# 1. Root-cause debugging (obra/superpowers, MIT)
npx skills add obra/superpowers --skill systematic-debugging

# 2. Reuse-first guardrail + diff audit (complement)
npx skills add Curbeloi/skills --skill reuse-before-write
```

Add `-g` to install them for your user instead of the current project.

### How the work is split

| | `systematic-debugging` | `reuse-before-write` |
|---|---|---|
| When | A bug, a failing test, unexpected behaviour | Any code change: features, fixes, refactors |
| Does | Finds the root cause before any fix | Finds existing code to reuse before writing; audits the diff before "done" |
| Output | A verified root cause | A recon report, an explicit reuse/extend/refactor/create decision, an audit checklist |

For bugs, `reuse-before-write` hands the diagnosis to `systematic-debugging` and takes over again
for the decision and the audit. Without it, it falls back to a short root-cause procedure.

### What is inside

```
skills/reuse-before-write/
├── SKILL.md                          # the 4-phase workflow
├── references/anti-patterns.md       # 7 anti-patterns, bad/good, in PHP, TypeScript and Rust
├── references/recon-report-template.md
└── scripts/
    ├── find-similar.sh               # files, definitions and identifiers matching domain terms
    ├── audit-diff.sh                 # GREEN/YELLOW/RED audit of the working tree or a branch
    └── lib.sh                        # shared helpers
```

The scripts need only `bash` (3.2+), `git` and `grep`. They use `rg` and `jscpd` when installed,
never download anything and never touch the network. You can run them by hand too:

```bash
bash .claude/skills/reuse-before-write/scripts/find-similar.sh invoice "format currency" tax
bash .claude/skills/reuse-before-write/scripts/audit-diff.sh          # vs HEAD
bash .claude/skills/reuse-before-write/scripts/audit-diff.sh main     # vs merge-base with main
```

### Check that it activates

Ask for a code change **without naming the skill**, e.g. *"show the invoice total formatted in
dollars"*. In Claude Code you will see a `Skill(reuse-before-write)` call before the first edit,
and the final message ends with `Root cause / Decision / Audit` lines. `claude --debug` also
logs skill loading.

### Evals

`evals/` holds ten small fixture repositories, the same five scenarios in TypeScript/PHP and in
Python, and a runner that executes each case with Claude Code, with and without the skill, and
checks the result:

| Scenario | TypeScript / PHP | Python | Expected |
|---|---|---|---|
| Duplication | 1: `formatCurrency()` exists | 6: `business_days_between()` exists | reuse it, no new helper or dependency |
| Patch vs root cause | 2: `null` in `calcularIVA()`, the XML parser reads the wrong node | 7: `None.lower()` in `send_welcome()`, the CSV has a BOM | fix the source, no `?? 0` / `if not email` |
| Tempting test | 3: discount test fails on a real bug | 8: pagination test fails on an off-by-one | fix the code, not the test |
| Existing duplicates | 4: two RUC validators, add cédula | 9: two phone normalizers, add suppliers | report or unify, no third copy |
| Legitimately new | 5: CSV export | 10: CSV export (stdlib, no pandas) | build it, without friction |

```bash
evals/run.sh                  # all cases, both variants; costs API usage
evals/run.sh --only 2,3
```

Latest results, including what they do *not* show, are in [evals/RESULTS.md](evals/RESULTS.md).

### Credits

`systematic-debugging` is by Jesse Vincent ([obra/superpowers](https://github.com/obra/superpowers), MIT).
This skill does not copy it; it delegates to it.

### License

MIT, see [LICENSE](LICENSE).

---

## Español

### `reuse-before-write`

Un guardarraíl ligero que actúa en **cada** cambio de código, sea una funcionalidad o un bug, con
dos puntos de control:

1. **Reconocimiento antes de escribir**: busca en el repositorio lo que ya existe (utilidades,
   servicios, librerías instaladas, callers) y obliga a decidir de forma explícita:
   *reutilizar → extender → refactorizar → crear*.
2. **Auditoría del diff antes de dar por terminado**: archivos nuevos, funciones nuevas con nombres
   parecidos a otras existentes, `try/catch` / `??` / `unwrap_or` / supresiones añadidos, tests
   modificados, dependencias nuevas y bloques copiados.

**El problema que resuelve.** Generar código es más barato que entenderlo, así que los agentes
tienden a duplicar funcionalidades con otro nombre (`formatDate` junto a `dateToString`,
`utils2.ts`, un segundo cliente HTTP) y a parchear síntomas (un `catch` que se traga el error,
`?? 0`, un test retocado hasta que pasa). Cada diff parece correcto por separado; juntos degradan el
código.

### Instalación

Complementa a [`systematic-debugging`](https://github.com/obra/superpowers/tree/main/skills/systematic-debugging)
de obra/superpowers. Instala los dos, en este orden:

```bash
# 1. Depuración por causa raíz (obra/superpowers, MIT)
npx skills add obra/superpowers --skill systematic-debugging

# 2. Reutilizar antes de escribir + auditoría del diff (complemento)
npx skills add Curbeloi/skills --skill reuse-before-write
```

Añade `-g` para instalarlos a nivel de usuario en lugar del proyecto actual.

### Cómo se reparten el trabajo

| | `systematic-debugging` | `reuse-before-write` |
|---|---|---|
| Cuándo | Un bug, un test que falla, un comportamiento inesperado | Cualquier cambio de código: funcionalidades, correcciones, refactors |
| Qué hace | Encuentra la causa raíz antes de corregir | Encuentra código existente para reutilizar antes de escribir y audita el diff antes de terminar |
| Resultado | Una causa raíz verificada | Un informe de reconocimiento, una decisión explícita (reutilizar/extender/refactorizar/crear) y un checklist de auditoría |

Ante un bug, `reuse-before-write` delega el diagnóstico en `systematic-debugging` y retoma el
control para la decisión y la auditoría. Si no está instalado, aplica un procedimiento corto de
causa raíz.

### Comprobar que se activa

Pide un cambio de código **sin nombrar el skill**, por ejemplo *"muestra el total de la factura
formateado en dólares"*. En Claude Code verás una llamada `Skill(reuse-before-write)` antes de la
primera edición, y el mensaje final termina con las líneas `Root cause / Decision / Audit`.

Los scripts solo necesitan `bash` (3.2+), `git` y `grep`; usan `rg` y `jscpd` si están instalados,
no descargan nada y no usan la red. Funcionan con cualquier lenguaje; los casos de prueba de
`evals/` cubren TypeScript, PHP y Python (ver la sección en inglés).

### Créditos y licencia

`systematic-debugging` es de Jesse Vincent ([obra/superpowers](https://github.com/obra/superpowers), MIT);
este skill no lo copia, delega en él. Licencia MIT, ver [LICENSE](LICENSE).
