#!/usr/bin/env bats
# Tests for exercise 16.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  BASH_IMPL="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/timestamp-log-bash.sh"
  AWK_IMPL="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/timestamp-log-awk.sh"
  CU_IMPL="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/timestamp-log-coreutils.sh"
  INPUT=$(printf '%s\t%s\n' 1747573931 'first' 1747573932 'second')$'\n'
}
teardown() { teardown_tmpdir; }

@test "[16] bash impl emits ISO timestamp + tab + message" {
  out=$(printf '%s' "$INPUT" | "$BASH_IMPL")
  # Each output line must start with an ISO-8601 timestamp, then a tab,
  # then the corresponding message. Match the exact shape on line 1.
  first_line=$(printf '%s' "$out" | head -1)
  [[ "$first_line" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}T[0-9]{2}:[0-9]{2}:[0-9]{2}[+-][0-9]{4}$'\t'first$ ]]
}

@test "[16] all three impls produce identical output" {
  # Strict equality, not just line count: the timestamp formatting,
  # ordering, and trailing newline must all match across implementations.
  bash_out=$(printf '%s' "$INPUT" | "$BASH_IMPL")
  awk_out=$( printf '%s' "$INPUT" | "$AWK_IMPL")
  cu_out=$(  printf '%s' "$INPUT" | "$CU_IMPL")
  [ "$bash_out" = "$awk_out" ]
  [ "$awk_out"  = "$cu_out"  ]
}

@test "[16] empty stdin produces empty output" {
  out=$(printf '' | "$BASH_IMPL")
  [ -z "$out" ]
}

@test "[16] bash impl: msg preserved verbatim" {
  out=$(printf '%s\t%s\n' 1747573931 'hello world!' | "$BASH_IMPL")
  [[ "$out" == *'hello world!'* ]]
}
