#!/usr/bin/env bash
# shellcheck source-path=SCRIPTDIR source=common.sh
. "$(dirname "$0")/common.sh"
grep -q 'business_days_between' app/orders/report.py; check "app/orders/report.py calls business_days_between" $? "$(grep -n business_days_between app/orders/report.py | head -2 | tr '\n' ' ')"
loop=$(added_matching 'weekday\(|isoweekday\(|timedelta\(days=1\)|busday' '^app/utils/dates.py$' -- app)
[ -z "$loop" ]; check "No new weekday loop outside app/utils/dates.py" $? "$loop"
no_new_dependency "No dependency added" requirements.txt pyproject.toml setup.py setup.cfg
five=$(python3 -c '
from datetime import date
from app.orders.models import Order
from app.orders.report import late_orders
rows = late_orders([Order("A1", "Ana", date(2026, 3, 2), date(2026, 3, 9))])
print("yes" if rows and 5 in [v for v in rows[0].values() if isinstance(v, int)] else "no: %r" % rows)' 2>&1 | tail -1)
[ "$five" = yes ]; check "A1 reports 5 business days late" $? "$five"
out=$(py_tests); check "Test suite passes" $? "$out"
