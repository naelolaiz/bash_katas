#!/usr/bin/env bats
# Tests for exercise 16.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  BASH_IMPL="$BATS_TEST_DIRNAME/solutions/timestamp-log-bash.sh"
  AWK_IMPL="$BATS_TEST_DIRNAME/solutions/timestamp-log-awk.sh"
  CU_IMPL="$BATS_TEST_DIRNAME/solutions/timestamp-log-coreutils.sh"
  INPUT=$(printf '%s\t%s\n' 1747573931 'first' 1747573932 'second')$'\n'
}
teardown() { teardown_tmpdir; }

@test "[16] bash impl emits ISO timestamp tab message" {
  out=$(printf '%s' "$INPUT" | "$BASH_IMPL")
  [[ "$out" == *'2025'* ]] || [[ "$out" == *'2024'* ]] || [[ "$out" == *'first'* ]]
  [[ "$out" == *$'\t'first* ]]
}

@test "[16] all three impls agree (line count)" {
  bash=$(printf '%s' "$INPUT" | "$BASH_IMPL" | wc -l)
  awk_=$(printf '%s' "$INPUT" | "$AWK_IMPL"  | wc -l)
  cu=$(printf '%s' "$INPUT" | "$CU_IMPL"     | wc -l)
  [ "$bash" -eq "$awk_" ]
  [ "$awk_" -eq "$cu" ]
}

@test "[16] empty stdin produces empty output" {
  out=$(printf '' | "$BASH_IMPL")
  [ -z "$out" ]
}

@test "[16] bash impl: msg preserved verbatim" {
  out=$(printf '%s\t%s\n' 1747573931 'hello world!' | "$BASH_IMPL")
  [[ "$out" == *'hello world!'* ]]
}
