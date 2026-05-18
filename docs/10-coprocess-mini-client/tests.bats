#!/usr/bin/env bats
# Tests for exercise 10.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/bc-client.sh"
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
  # close stdin immediately
  run timeout 5 bash -c '"$0" < /dev/null' "$CMD"
  [ "$status" -ne 124 ]   # didn't time out
}

@test "[10] -t TIMEOUT accepted as flag" {
  out=$(printf 'quit\n' | "$CMD" -t 1 2>/dev/null)
  # script should produce SOMETHING (or nothing) but not crash
  true
}
