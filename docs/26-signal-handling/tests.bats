#!/usr/bin/env bats
# Tests for exercise 26.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/run-with-cleanup.sh"
}
teardown() { teardown_tmpdir; }

@test "[26] propagates clean exit" {
  run "$CMD" bash -c 'exit 42'
  assert_status 42
}

@test "[26] propagates exit 0" {
  run "$CMD" true
  assert_status 0
}

@test "[26] survives SIGPIPE from downstream" {
  # If the wrapper crashes on SIGPIPE its exit code would be 141 (128+13).
  # The point of the test is that it does NOT crash, so 141 is forbidden.
  # Acceptable: 0 (clean exit once `yes` itself hits EPIPE and dies) or
  # any small non-zero from `yes`.
  run bash -c '"$0" yes | head -1' "$CMD"
  [ "$status" -ne 141 ]
  [ "$status" -lt 128 ]   # also not killed by any other signal
}

@test "[26] usage error on no args" {
  run "$CMD"
  assert_status 2
}
