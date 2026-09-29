# A Python except whose only body is pass, on the next line.
FIXTURE=9-py-unify-phone
change() {
  printf 'def f(x):\n    try:\n        return int(x)\n    except ValueError:\n        pass\n' >> app/suppliers/service.py
}
expect() { expect_line '^  \[red\] 1 empty catch/except block'; }
