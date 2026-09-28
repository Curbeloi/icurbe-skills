import sys
from pathlib import Path

from app.importers.customers_csv import load_customers
from app.notifications.welcome import OUTBOX, send_welcome


def main(path: str) -> None:
    for customer in load_customers(Path(path)):
        send_welcome(customer)
    print(f"{len(OUTBOX)} bienvenidas enviadas")


if __name__ == "__main__":
    main(sys.argv[1] if len(sys.argv) > 1 else "samples/clientes.csv")
