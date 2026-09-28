import re


def clean_phone(value: str) -> str:
    # same rule as customers, kept here so leads does not import customers
    only_digits = re.sub(r"[^0-9]", "", value)
    if only_digits[:3] == "593":
        only_digits = only_digits[3:]
    while only_digits.startswith("0"):
        only_digits = only_digits[1:]
    if not 8 <= len(only_digits) <= 9:
        raise ValueError("invalid phone")
    return f"+593{only_digits}"


def create_lead(name: str, phone: str, source: str = "web") -> dict:
    return {"name": name.strip(), "phone": clean_phone(phone), "source": source}
