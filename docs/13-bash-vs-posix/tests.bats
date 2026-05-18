#!/usr/bin/env bats
# Tests for exercise 13.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  BASH_IMPL="$BATS_TEST_DIRNAME/solutions/tool.bash"
  SH_IMPL="$BATS_TEST_DIRNAME/solutions/tool.sh"
  INPUT=$(printf '%s\n' '2026-05-18 INFO api started' \
                       '2026-05-18 ERROR api failed' \
                       '2026-05-18 INFO db ready')
}
teardown() { teardown_tmpdir; }

@test "[13] bash version: counts pairs" {
  out=$(printf '%s\n' "$INPUT" | bash "$BASH_IMPL")
  [[ "$out" == *"INFO api 1"* ]]
  [[ "$out" == *"ERROR api 1"* ]]
  [[ "$out" == *"INFO db 1"* ]]
}

@test "[13] POSIX version: same output as bash version" {
  bash_out=$(printf '%s\n' "$INPUT" | bash "$BASH_IMPL")
  sh_out=$(printf '%s\n' "$INPUT" | sh "$SH_IMPL")
  [ "$bash_out" = "$sh_out" ]
}

@test "[13] POSIX version runs under dash" {
  if ! command -v dash >/dev/null; then skip 'dash not installed'; fi
  out=$(printf '%s\n' "$INPUT" | dash "$SH_IMPL")
  [[ "$out" == *"INFO api 1"* ]]
}

@test "[13] POSIX version passes shellcheck -s sh" {
  run shellcheck -s sh "$SH_IMPL"
  assert_status 0
}
