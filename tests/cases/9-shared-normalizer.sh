# The right answer to eval 9: reuse the existing normalizer and report the leads copy.
FIXTURE=9-py-unify-phone
CHECK=9
SEARCH=(phone)
FINAL_MESSAGE='Uso _normalize_phone de customers; app/leads/service.py:clean_phone es otra copia de la misma regla, propongo unificarlas.'
change() {
  cat > app/suppliers/service.py <<'PY'
from app.customers.service import _normalize_phone


def create_supplier(company: str, tax_id: str, phone: str) -> dict:
    return {"company": company.strip(), "tax_id": tax_id.strip(), "phone": _normalize_phone(phone)}
PY
}
expect() {
  expect_no_red; expect_quiet_section 6; expect_quiet_section 7
  expect_checks PPPP
  expect_found '_normalize_phone'; expect_found 'clean_phone'   # both existing normalizers
}
