import math
from collections.abc import Sequence
from typing import TypeVar

T = TypeVar("T")


def paginate(items: Sequence[T], page: int, per_page: int = 20) -> dict:
    """Returns one page of `items`. Pages are 1-based: page=1 is the first page."""
    if page < 1 or per_page < 1:
        raise ValueError("page and per_page must be >= 1")
    start = page * per_page
    return {
        "items": list(items[start:start + per_page]),
        "page": page,
        "total_pages": math.ceil(len(items) / per_page),
    }
