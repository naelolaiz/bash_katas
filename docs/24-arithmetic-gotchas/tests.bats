#!/usr/bin/env bats
# Tests for exercise 24.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/uptime-summary.sh"
}
teardown() { teardown_tmpdir; }

@test "[24] processes a synthetic /proc/uptime" {
  # 1 day, 1 hour, 1 minute, 1 second = 90061 secs; idle = 45000
  echo '90061.00 45000.00' > "$TMPDIR_FOR_TEST/uptime"
  out=$("$CMD" "$TMPDIR_FOR_TEST/uptime")
  [[ "$out" == *'1d 1h 1m'* ]]
}

@test "[24] zero idle is handled" {
  echo '100.00 0.00' > "$TMPDIR_FOR_TEST/uptime"
  out=$("$CMD" "$TMPDIR_FOR_TEST/uptime")
  [[ "$out" == *'0.0%'* ]]
}

@test "[24] huge uptime prints with thousands separator (when locale set)" {
  echo '1234567.00 600000.00' > "$TMPDIR_FOR_TEST/uptime"
  out=$("$CMD" "$TMPDIR_FOR_TEST/uptime")
  [[ "$out" == *'1,234,567'* || "$out" == *'1234567'* ]]
}

@test "[24] missing /proc/uptime exits 2" {
  run "$CMD" /no/such/file
  assert_status 2
}
