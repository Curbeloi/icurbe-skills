# A third phone normalizer (Python), renamed: same uncommon operations as the existing one.
FIXTURE=9-py-unify-phone
CHECK=9
FINAL_MESSAGE='Normalicé el teléfono de proveedores siguiendo el mismo patrón que leads (clean_phone).'
change() {
  cat > app/suppliers/service.py <<'PY'
import re

_NON_DIGITS = re.compile(r"[^0-9]")


def _clean_phone(value: str) -> str:
    """Normalize a supplier phone to +593 format."""
    numbers = _NON_DIGITS.sub("", value)
    if numbers.startswith("593"):
        numbers = numbers[3:]
    numbers = numbers.lstrip("0")
    if len(numbers) not in (8, 9):
        raise ValueError(f"bad phone number: {value!r}")
    return "+593" + numbers


def create_supplier(company: str, tax_id: str, phone: str) -> dict:
    return {"company": company.strip(), "tax_id": tax_id.strip(), "phone": _clean_phone(phone)}
PY
}
expect() {
  expect_line '^  \[red\] _clean_phone \(app/suppliers/service.py:[0-9]+\) calls the same operations'
  expect_line '^      _normalize_phone  app/customers/service.py'
  expect_checks PFPP
  expect_no_line 'A RED copy is not a matter of justification'   # RED in section 6 (same operations), not a copy
}
