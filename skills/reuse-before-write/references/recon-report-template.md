# Recon report template

Write this before Phase 3. One line per item; drop fields that do not apply.

```markdown
## Recon
- Task: <one line>
- Terms searched: <list, including synonyms and variants>
- Found: <path:symbol> — <what it does> — reusable: yes | no | partial
- Found: <path:symbol> — <what it does> — reusable: yes | no | partial
- Overlaps with: <path:symbol> — <same output or effect it already produces> — yes | no | partial
- Callers affected: <list of path:line, or "none (new code)">
- Root cause (bugs only): <one sentence>
- Decision: reuse | extend | refactor | create — <one-line justification>
```

## Example: feature

```markdown
## Recon
- Task: show the invoice total formatted in US dollars
- Terms searched: currency, money, format, amount, total, price, usd; primitives: NumberFormat, toFixed
- Found: src/utils/money.ts:formatCurrency — Intl.NumberFormat wrapper, takes (amount, currency) — reusable: yes
- Found: package.json — no currency library installed
- Overlaps with: src/utils/money.ts:formatCurrency — already produces "$1,234.50" — yes
- Callers affected: src/views/invoice.ts:renderInvoice
- Decision: reuse — formatCurrency(total, "USD") already does exactly this
```

## Example: bug

```markdown
## Recon
- Task: fix the null error in calcularIVA
- Terms searched: iva, tax, vat, rate, tarifa, parse, xml
- Found: src/Tax/IvaCalculator.php:calcularIVA — multiplies base by rate — reusable: yes
- Found: src/Xml/InvoiceParser.php:parse — builds the Invoice from XML — reusable: yes (bug here)
- Callers affected: src/Invoice/InvoiceService.php:total, tests/IvaCalculatorTest.php
- Root cause: InvoiceParser reads <tarifaIva> but the SRI XML names the node <tarifa>, so rate is null
- Decision: extend — read the correct node in the parser; calcularIVA stays unchanged
```

## Example: nothing to reuse

```markdown
## Recon
- Task: export the report as CSV
- Terms searched: csv, export, download, serialize, report; effects: file download, text/csv
- Found: nothing for CSV; src/report/buildReport.ts returns rows as objects — reusable: yes (input)
- Found: src/report/renderHtml.ts — renders the same rows as HTML — reusable: no (other format)
- Found: package.json — no CSV library
- Overlaps with: none (no code produces CSV or any delimited export)
- Decision: create — new src/report/toCsv.ts (about 20 lines, RFC 4180 quoting); no dependency needed
```
