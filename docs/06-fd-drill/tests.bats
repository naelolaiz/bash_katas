#!/usr/bin/env bats
# Tests for exercise 6.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/runlog.sh"
  LOG="$TMPDIR_FOR_TEST/run.log"
}
teardown() { teardown_tmpdir; }

@test "[6] propagates command's exit code" {
  run "$CMD" "$LOG" bash -c 'exit 42'
  assert_status 42
}

@test "[6] writes stdout to the log" {
  "$CMD" --quiet "$LOG" bash -c 'echo hello-stdout' || true
  sleep 0.2   # process substitution flushes asynchronously
  grep -q 'hello-stdout' "$LOG"
}

@test "[6] writes stderr to the log with a marker" {
  "$CMD" --quiet "$LOG" bash -c 'echo oops >&2' || true
  sleep 0.2
  grep -q 'oops' "$LOG"
  grep -q '\[stderr\]' "$LOG"
}

@test "[6] logfile created if missing" {
  rm -f "$LOG"
  "$CMD" --quiet "$LOG" true
  sleep 0.2
  [ -f "$LOG" ]
}

@test "[6] usage error without arguments" {
  run "$CMD"
  assert_status 2
}
