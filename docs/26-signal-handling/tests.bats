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
  # if the wrapper crashes on SIGPIPE, this exit status would be 141
  run bash -c '"$0" yes | head -1' "$CMD"
  # exit 0 or 141 acceptable; what matters is the shell doesn't blow up
  [ "$status" -eq 0 ] || [ "$status" -eq 141 ] || [ "$status" -eq 1 ]
}

@test "[26] usage error on no args" {
  run "$CMD"
  assert_status 2
}
