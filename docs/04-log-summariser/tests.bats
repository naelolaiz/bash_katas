#!/usr/bin/env bats
# Tests for exercise 4.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/log-count.sh"
}
teardown() { teardown_tmpdir; }

@test "[4] simple counts" {
  out=$(printf '%s\n' \
    '2026-05-18 INFO api started' \
    '2026-05-18 INFO api ready' \
    '2026-05-18 ERROR api failed' \
    '2026-05-18 WARN db slow' \
    | "$CMD")
  [[ "$out" == *"INFO api 2"* ]]
  [[ "$out" == *"ERROR api 1"* ]]
  [[ "$out" == *"WARN db 1"* ]]
}

@test "[4] tolerates blank lines" {
  printf '%s\n' '' '2026-05-18 INFO api started' '' | run "$CMD"
  # bats `run` already redirected stdin; redo without piping
  run bash -c 'printf "%s\n" "" "2026-05-18 INFO api started" "" | "$0"' "$CMD"
  assert_status 0
}

@test "[4] malformed line exits 1" {
  run bash -c 'printf "%s\n" "not a log line" | "$0"' "$CMD"
  assert_status 1
}

@test "[4] empty input is OK and produces no output" {
  run bash -c 'printf "" | "$0"' "$CMD"
  assert_status 0
  [ -z "$output" ]
}

@test "[4] output sorted under LC_ALL=C (stable across machines)" {
  out1=$(printf '%s\n' '2026-05-18 INFO a x' '2026-05-18 INFO B y' | LC_ALL=en_US.UTF-8 "$CMD")
  out2=$(printf '%s\n' '2026-05-18 INFO a x' '2026-05-18 INFO B y' | LC_ALL=C            "$CMD")
  [ "$out1" = "$out2" ]
}
