#!/usr/bin/env bats
# Tests for exercise 10.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/bc-client.sh"
}
teardown() { teardown_tmpdir; }

@test "[10] single expression" {
  out=$(printf '2+2\nquit\n' | "$CMD" 2>/dev/null)
  [[ "$out" == *'= 4'* ]]
}

@test "[10] multiple expressions" {
  out=$(printf '%s\n' '3*4' '7-2' 'quit' | "$CMD" 2>/dev/null)
  [[ "$out" == *'= 12'* ]]
  [[ "$out" == *'= 5'* ]]
}

@test "[10] EOF triggers clean shutdown" {
  # stdin closed immediately; the client should drop out of its read loop,
  # tear down bc, and exit cleanly (0) within the timeout.
  run timeout 5 bash -c '"$0" < /dev/null' "$CMD"
  assert_status 0
}

@test "[10] -t TIMEOUT accepted as flag" {
  # Flag must be parsed without error; the client should still cleanly
  # shut down on quit (and not exceed the outer timeout).
  run timeout 5 bash -c 'printf "quit\n" | "$0" -t 1' "$CMD"
  assert_status 0
}
