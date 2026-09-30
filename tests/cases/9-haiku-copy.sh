# Haiku 4.5's answer to eval 9 with the skill loaded (2026-09-29), rebuilt from the run's audit
# output: _normalize_phone pasted into suppliers under the same name, 10 lines identical to
# customers. The audit said RED; the model called it "intentional duplication, consistent with
# the architecture" and kept it.
FIXTURE=9-py-unify-phone
CHECK=9
FINAL_MESSAGE='Decision: Create (duplicate). Patrón del proyecto: normalización de teléfono duplicada entre módulos (customers/leads evitan imports cruzados). Suppliers ahora sigue el mismo patrón.'
change() {
  cat > app/suppliers/service.py <<'PY'
import re

_DIGITS = re.compile(r"\D+")


def _normalize_phone(raw: str) -> str:
    """Ecuadorian number in E.164: '099 123 4567' -> '+593991234567'."""
    digits = _DIGITS.sub("", raw)
    if digits.startswith("593"):
        digits = digits[3:]
    digits = digits.lstrip("0")
    if len(digits) not in (8, 9):
        raise ValueError(f"invalid phone: {raw!r}")
    return "+593" + digits


def create_supplier(company: str, tax_id: str, phone: str) -> dict:
    return {"company": company.strip(), "tax_id": tax_id.strip(), "phone": _normalize_phone(phone)}
PY
}
expect() {
  expect_line '^  \[red\] app/suppliers/service.py: .* in app/customers/service.py'
  expect_line 'A RED copy is not a matter of justification'
  expect_checks PFPP
}
