from dataclasses import dataclass
from datetime import date


@dataclass
class Order:
    id: str
    customer: str
    promised_date: date
    delivered_date: date | None = None
