#!/usr/bin/env bats
# Tests for exercise 23.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/locale-bomb.sh"
}
teardown() { teardown_tmpdir; }

@test "[23] runs without error" {
  run "$CMD"
  assert_status 0
}

@test "[23] demonstrates LC_ALL=C sort difference" {
  out=$("$CMD")
  [[ "$out" == *'LC_ALL=C'* ]]
}

@test "[23] demonstrates [[:upper:]] use" {
  out=$("$CMD")
  [[ "$out" == *'[[:upper:]]'* ]]
}

@test "[23] demonstrates version sort" {
  out=$("$CMD")
  [[ "$out" == *'-V'* ]]
}
