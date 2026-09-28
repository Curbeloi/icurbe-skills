from app.pagination import paginate

CATALOG = [f"SKU-{n:03d}" for n in range(1, 8)]


def list_products(page: int = 1) -> dict:
    return paginate(CATALOG, page, per_page=3)
