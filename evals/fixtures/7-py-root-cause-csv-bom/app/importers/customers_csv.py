import csv
from dataclasses import dataclass
from pathlib import Path


@dataclass
class Customer:
    email: str | None
    name: str
    city: str


def load_customers(path: Path) -> list[Customer]:
    with path.open(encoding="utf-8", newline="") as fh:
        reader = csv.DictReader(fh)
        return [
            Customer(email=row.get("email"), name=row["nombre"], city=row["ciudad"])
            for row in reader
        ]
