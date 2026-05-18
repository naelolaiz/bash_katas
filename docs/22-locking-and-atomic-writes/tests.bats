#!/usr/bin/env bats
# Tests for exercise 22.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  SI="$BATS_TEST_DIRNAME/solutions/single-instance.sh"
  AW="$BATS_TEST_DIRNAME/solutions/atomic-write.sh"
  LOCK="$TMPDIR_FOR_TEST/lock"
}
teardown() { teardown_tmpdir; }

@test "[22] single-instance: first run succeeds" {
  run "$SI" "$LOCK" true
  assert_status 0
}

@test "[22] single-instance: second concurrent run rejected" {
  # start a long-running first run in background
  "$SI" "$LOCK" sleep 2 &
  bg=$!
  sleep 0.3
  run "$SI" "$LOCK" true
  assert_status 1
  wait "$bg" 2>/dev/null || true
}

@test "[22] single-instance: --wait blocks until lock free" {
  "$SI" "$LOCK" sleep 1 &
  bg=$!
  sleep 0.2
  run "$SI" --wait 3 "$LOCK" true
  assert_status 0
  wait "$bg" 2>/dev/null || true
}

@test "[22] atomic-write: replaces TARGET" {
  target="$TMPDIR_FOR_TEST/t"
  printf 'old\n' > "$target"
  printf 'new\n' | "$AW" "$target"
  [ "$(cat "$target")" = 'new' ]
}

@test "[22] atomic-write: preserves mode" {
  target="$TMPDIR_FOR_TEST/t"
  printf 'old\n' > "$target"
  chmod 0640 "$target"
  printf 'new\n' | "$AW" "$target"
  perms=$(stat -c '%a' "$target")
  [ "$perms" = '640' ]
}
