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


def create_customer(name: str, phone: str) -> dict:
    return {"name": name.strip(), "phone": _normalize_phone(phone)}
