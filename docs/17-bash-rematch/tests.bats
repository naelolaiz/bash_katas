#!/usr/bin/env bats
# Tests for exercise 17.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/parse-log.sh"
}
teardown() { teardown_tmpdir; }

@test "[17] parses a well-formed line" {
  in='2026-05-18T14:32:11+0200 [INFO] api.request id=abc-123 took=42ms'
  out=$(printf '%s\n' "$in" | "$CMD")
  [[ "$out" == *'INFO'* ]]
  [[ "$out" == *'api.request'* ]]
  [[ "$out" == *'abc-123'* ]]
  [[ "$out" == *'42'* ]]
}

@test "[17] malformed line exits 1" {
  run bash -c 'printf "%s\n" "not a log line" | "$0"' "$CMD"
  assert_status 1
}

@test "[17] mixed input: good + bad reports bad to stderr, exits 1" {
  in1='2026-05-18T14:32:11+0200 [INFO] api.request id=abc-123 took=42ms'
  in2='garbage line'
  run bash -c 'printf "%s\n%s\n" "$1" "$2" | "$0"' "$CMD" "$in1" "$in2"
  assert_status 1
  assert_output_contains 'abc-123'
}

@test "[17] empty stdin is OK" {
  run bash -c 'printf "" | "$0"' "$CMD"
  assert_status 0
}
