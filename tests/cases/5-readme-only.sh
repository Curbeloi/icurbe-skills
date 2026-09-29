# Mentioning CSV in the README is not an exporter.
FIXTURE=5-ts-legit-new-csv
CHECK=5
change() { echo 'CSV export: coming soon.' >> README.md; }
expect() { expect_checks FFPP; }
