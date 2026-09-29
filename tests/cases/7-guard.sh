# The guard where it explodes: nobody gets a welcome and nothing fails.
FIXTURE=7-py-root-cause-csv-bom
CHECK=7
FINAL_MESSAGE='Arreglado: si el cliente no tiene email no se envía la bienvenida.'
change() {
  perl -0pi -e 's/(def send_welcome\(customer: Customer\) -> None:\n)/$1    if customer.email is None:\n        return\n/' app/notifications/welcome.py
}
expect() { expect_checks FFFF; }
