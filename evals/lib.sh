# shellcheck shell=bash
# Shared by evals/run.sh and tests/run.sh. Sourced, never executed.

EVALS_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# fixture_copy FIXTURE DEST: copies evals/fixtures/FIXTURE to DEST as a git repository with no
# commit yet, so the caller can add files (skills, for instance) to the baseline first.
fixture_copy() {
  cp -R "$EVALS_DIR/fixtures/$1" "$2" && git -C "$2" init -q
}

# fixture_commit DIR: commits everything in DIR as the baseline the change is compared against.
fixture_commit() {
  git -C "$1" add -A && git -C "$1" -c user.name=eval -c user.email=eval@localhost commit -qm fixture
}
