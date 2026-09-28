# Anti-patterns catalogue

Each entry: what it looks like, why it hurts, and a bad/good pair. Examples rotate between PHP,
TypeScript and Rust; the pattern is the same in every language.

Contents:
1. Duplicate function under another name
2. Silencing try/catch
3. Special-case `if` for the reported input
4. Test edited to pass
5. Fallback that hides corrupt data
6. Redundant dependency
7. Copy-paste with a small variation instead of a parameter

---

## 1. Duplicate function under another name

The new function does what an existing one does, under a name you did not search for. Now two
implementations drift apart, and the next bug gets fixed in only one of them.

**TypeScript: bad**
```ts
// src/views/invoice.ts
function toDollars(n: number): string {
  return "$" + n.toFixed(2);            // src/utils/money.ts:formatCurrency already exists
}
```
**TypeScript: good**
```ts
import { formatCurrency } from "../utils/money";
const label = formatCurrency(invoice.total, "USD");
```

**How to catch it:** search verbs *and* nouns with variants (`format`, `currency`, `money`,
`price`, `amount`), and run `audit-diff.sh`, which lists similarly named symbols for every new
definition.

---

## 2. Silencing try/catch

The error goes away, the bug does not. It resurfaces later, far from its cause and without a
stack trace.

**PHP: bad**
```php
try {
    $invoice = $parser->parse($xml);
} catch (\Throwable $e) {
    $invoice = new Invoice();            // empty invoice flows on as if valid
}
```
**PHP: good**
```php
// Fix why parse() throws (see the root cause). If the XML can legitimately be invalid
// (user upload), catch the specific exception and surface it:
try {
    $invoice = $parser->parse($xml);
} catch (InvalidInvoiceXml $e) {
    throw new UserFacingError("The invoice XML is invalid: " . $e->getMessage(), previous: $e);
}
```

---

## 3. Special-case `if` for the reported input

The fix recognises the exact input from the bug report instead of the class of inputs that
triggers it.

**Rust: bad**
```rust
fn parse_ruc(s: &str) -> Result<Ruc, Error> {
    if s == "0990000000001" { return Ok(Ruc::default()); } // the one the customer reported
    validate(s)
}
```
**Rust: good**
```rust
fn parse_ruc(s: &str) -> Result<Ruc, Error> {
    // Root cause: validate() rejected RUCs for public entities (third digit 6), which use a
    // different check digit. Handle that class of input, and test it.
    match s.chars().nth(2) {
        Some('6') => validate_public(s),
        _ => validate(s),
    }
}
```

---

## 4. Test edited to pass

A red test is information. Changing its expectation to the current (wrong) output deletes the
information and blesses the bug.

**TypeScript: bad**
```ts
// was: expect(applyDiscount(100, 0.1)).toBe(90);
expect(applyDiscount(100, 0.1)).toBe(99.9);   // "updated test"
```
**TypeScript: good**
```ts
// The test was right; applyDiscount subtracted the rate instead of multiplying. Fix the code:
export const applyDiscount = (price: number, rate: number) => price * (1 - rate);
```
Editing a test is correct only when the test itself is wrong (it asserts a behaviour the spec does
not require). Then say why in the summary.

---

## 5. Fallback that hides corrupt data

`?? 0`, `|| ""`, `unwrap_or_default()` and `?: 0` turn "we lost the data" into "the data is
zero". Totals come out wrong and nobody gets an error.

**PHP: bad**
```php
function calcularIVA(Invoice $inv): float {
    return $inv->base * ($inv->rate ?? 0);    // rate is null because the parser misses a node
}
```
**PHP: good**
```php
// Fix the parser so rate is always set, and make the invariant explicit:
function calcularIVA(Invoice $inv): float {
    if ($inv->rate === null) {
        throw new LogicException("Invoice {$inv->number} has no VAT rate");
    }
    return $inv->base * $inv->rate;
}
```

**Rust: bad** `let rate = row.get("rate").and_then(parse).unwrap_or(0.0);`
**Rust: good** `let rate = row.get("rate").ok_or(Error::MissingRate)?.parse()?;`

A default is fine when absence is a legitimate business case ("no discount means 0"). Write that
reason next to it.

---

## 6. Redundant dependency

A second library for something the project already does: `moment` next to `date-fns`, `axios`
next to a wrapped `fetch`, `guzzle` next to Symfony HttpClient, `chrono` next to `time`.

**Bad**
```bash
npm install dayjs        # package.json already has date-fns
```
**Good**
```ts
import { format } from "date-fns";       // the project's existing choice
```
Check the manifest (`package.json`, `composer.json`, `Cargo.toml`, `requirements.txt`) and the
existing wrappers (`src/lib/http.ts`, `app/Services/HttpClient.php`) before adding anything.

---

## 7. Copy-paste with a small variation instead of a parameter

The block is duplicated so that one line can differ. Fixes now have to be applied twice, and they
won't be.

**PHP: bad**
```php
function validarRuc(string $ruc): bool {
    if (!preg_match('/^\d{13}$/', $ruc)) return false;
    return modulo10(substr($ruc, 0, 10)) && substr($ruc, 10) === '001';
}
function validarCedula(string $ced): bool {       // copied, then trimmed
    if (!preg_match('/^\d{10}$/', $ced)) return false;
    return modulo10($ced);
}
```
**PHP: good**
```php
function validarIdentificacion(string $id, TipoId $tipo): bool {
    if (!preg_match("/^\d{{$tipo->length()}}$/", $id)) return false;
    $ok = modulo10(substr($id, 0, 10));
    return $tipo === TipoId::Ruc ? $ok && substr($id, 10) === '001' : $ok;
}
```
When two near-copies already exist, unify them first (Phase 3, option 3), with the user's OK if
other modules use them, then add the new case to the unified version.

**TypeScript: bad**
```ts
export async function getUsers()  { const r = await fetch(`${API}/users`);  if (!r.ok) throw new Error(r.statusText); return r.json(); }
export async function getOrders() { const r = await fetch(`${API}/orders`); if (!r.ok) throw new Error(r.statusText); return r.json(); }
```
**TypeScript: good**
```ts
async function getJson<T>(path: string): Promise<T> {
  const r = await fetch(`${API}${path}`);
  if (!r.ok) throw new Error(r.statusText);
  return r.json();
}
export const getUsers = () => getJson<User[]>("/users");
export const getOrders = () => getJson<Order[]>("/orders");
```
