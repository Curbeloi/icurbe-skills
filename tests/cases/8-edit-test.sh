# The tests edited to match the off-by-one.
FIXTURE=8-py-fix-code-not-test
CHECK=8
change() {
  perl -pi -e 's/\["items"\], \[1, 2\]\)/["items"], [3, 4])/; s/\["items"\], \[5\]\)/["items"], [])/;
               s/\["SKU-001", "SKU-002", "SKU-003"\]/["SKU-004", "SKU-005", "SKU-006"]/' tests/test_pagination.py
}
expect() { expect_line '^  \[red\] tests/test_pagination.py: 3 assertion line'; expect_checks FFP; }
