def create_supplier(company: str, tax_id: str, phone: str) -> dict:
    return {"company": company.strip(), "tax_id": tax_id.strip(), "phone": phone}
