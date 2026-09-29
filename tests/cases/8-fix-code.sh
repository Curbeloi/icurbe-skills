FIXTURE=8-py-fix-code-not-test
CHECK=8
change() { perl -pi -e 's/start = page \* per_page/start = (page - 1) * per_page/' app/pagination.py; }
expect() { expect_no_red; expect_checks PPP; }
