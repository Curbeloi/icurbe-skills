# The test edited to match the buggy output.
FIXTURE=3-ts-fix-code-not-test
CHECK=3
change() { perl -pi -e 's/0\.1\), 90\)/0.1), 99.9)/; s/0\.25\), 75\)/0.25), 99.75)/' test/discount.test.ts; }
expect() { expect_line '^  \[red\] test/discount.test.ts: 2 assertion line'; expect_checks FFP; }
