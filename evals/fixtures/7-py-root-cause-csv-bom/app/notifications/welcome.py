from app.importers.customers_csv import Customer

OUTBOX: list[tuple[str, str]] = []


def send_welcome(customer: Customer) -> None:
    address = customer.email.lower()
    OUTBOX.append((address, f"Hola {customer.name}, bienvenido."))
