#!/usr/bin/env bats
# Tests for exercise 1.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/expand-lab.sh"
}
teardown() { teardown_tmpdir; }

@test "[1] starter exists" {
  [ -x "$BATS_TEST_DIRNAME/starter.sh" ]
}

@test "[1] solution: normal path" {
  run "$CMD" /tmp/archive.tar.gz
  assert_status 0
  assert_output_contains 'base'
  assert_output_contains 'archive.tar.gz'
  assert_output_contains 'gz'
}

@test "[1] solution: filename with spaces" {
  run "$CMD" "a b.txt"
  assert_status 0
  assert_output_contains 'a b.txt'
}

@test "[1] solution: empty input arg" {
  run "$CMD" ""
  assert_status 0
}

@test "[1] solution: --quoted produces no raw newline in value" {
  run "$CMD" --quoted $'a\nb'
  assert_status 0
  [[ "$output" != *$'a\nb'* ]]
}

@test "[1] usage error on no args" {
  run "$CMD"
  assert_status 2
}
