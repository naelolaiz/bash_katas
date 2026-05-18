# shellcheck shell=bash
# shellcheck disable=SC2154   # $status/$output/$lines are Bats-provided
# Shared Bats helpers. Load with:
#
#   load ../../lib/test_helpers
#
# (Bats `load` automatically appends .bash and strips leading ../)

# Locate the project root by walking up from BATS_TEST_DIRNAME.
project_root() {
  local d=$BATS_TEST_DIRNAME
  while [[ ! -f $d/Makefile && $d != / ]]; do
    d=$(dirname "$d")
  done
  printf '%s\n' "$d"
}

# Create a private temp dir, registered for cleanup on test exit.
setup_tmpdir() {
  TMPDIR_FOR_TEST=$(mktemp -d -t bats-katas.XXXXXX)
  export TMPDIR_FOR_TEST
}

teardown_tmpdir() {
  [[ -n "${TMPDIR_FOR_TEST:-}" && -d "$TMPDIR_FOR_TEST" ]] && rm -rf "$TMPDIR_FOR_TEST"
}

# Resolve a path under data/fixtures relative to project root.
fixture_path() {
  printf '%s/data/fixtures/%s\n' "$(project_root)" "$1"
}

# Create the canonical "weird filenames" corpus inside a directory.
seed_weird_filenames() {
  local root=$1
  mkdir -p "$root"
  : > "$root/a b.txt"
  : > "$root/normal.txt"
  : > "$root/--danger"
  : > "$root/"$'embedded\nnewline.txt'
  : > "$root/"'*.txt'
}

# Assertion helper: fail with a useful message including the captured output.
assert_status() {
  local expected=$1
  [[ "$status" -eq "$expected" ]] || {
    printf 'expected exit %d, got %d\n' "$expected" "$status" >&2
    printf 'output was:\n%s\n' "$output" >&2
    return 1
  }
}

assert_output_contains() {
  local needle=$1
  [[ "$output" == *"$needle"* ]] || {
    printf 'expected output to contain: %q\n' "$needle" >&2
    printf 'output was:\n%s\n' "$output" >&2
    return 1
  }
}
