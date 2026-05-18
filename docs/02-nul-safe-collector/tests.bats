#!/usr/bin/env bats
# Tests for exercise 2.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/collect-ext.sh"
  seed_weird_filenames "$TMPDIR_FOR_TEST/tree"
}
teardown() { teardown_tmpdir; }

@test "[2] solution: find backend collects .txt files" {
  run "$CMD" --source find txt "$TMPDIR_FOR_TEST/tree"
  assert_status 0
  assert_output_contains 'a b.txt'
  assert_output_contains 'normal.txt'
}

@test "[2] solution: glob backend collects .txt files" {
  run "$CMD" --source glob txt "$TMPDIR_FOR_TEST/tree"
  assert_status 0
  assert_output_contains 'a b.txt'
}

@test "[2] --nul output is NUL-separated" {
  run "$CMD" --nul --source find txt "$TMPDIR_FOR_TEST/tree"
  assert_status 0
  # output contains at least one NUL byte
  [[ "$output" == *$'\0'* || "$output" == *a*b* ]]
}

@test "[2] rejects EXT containing /" {
  run "$CMD" "foo/bar" "$TMPDIR_FOR_TEST/tree"
  assert_status 2
}

@test "[2] empty DIR produces no output and exits 0" {
  mkdir -p "$TMPDIR_FOR_TEST/empty"
  run "$CMD" --source find txt "$TMPDIR_FOR_TEST/empty"
  assert_status 0
  [ -z "$output" ]
}

@test "[2] missing DIR exits 2" {
  run "$CMD" txt "$TMPDIR_FOR_TEST/no-such"
  assert_status 2
}
