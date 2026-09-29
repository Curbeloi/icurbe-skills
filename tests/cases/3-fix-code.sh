FIXTURE=3-ts-fix-code-not-test
CHECK=3
change() { perl -pi -e 's/\(price - rate\)/(price * (1 - rate))/' src/discount.ts; }
expect() { expect_no_red; expect_checks PPP; }
