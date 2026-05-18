#!/usr/bin/env bats
# Tests for exercise 21.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/log-analyse.sh"
  LOG="$TMPDIR_FOR_TEST/access.log"
  ALLOW="$TMPDIR_FOR_TEST/allow"
  # realistic CLF format: [date timezone] makes the date a 2-token field
  cat > "$LOG" <<'EOF'
10.0.0.1 - - [18/May/2026:12:00:00 +0000] "GET /a HTTP/1.1" 200 100 -
10.0.0.1 - - [18/May/2026:12:00:01 +0000] "GET /b HTTP/1.1" 500 50 -
10.0.0.2 - - [18/May/2026:12:00:02 +0000] "GET /a HTTP/1.1" 200 100 -
10.0.0.3 - - [18/May/2026:12:00:03 +0000] "GET /c HTTP/1.1" 500 50 -
EOF
  printf '%s\n' 10.0.0.1 10.0.0.2 > "$ALLOW"
}
teardown() { teardown_tmpdir; }

@test "[21] reports top IPs" {
  out=$("$CMD" -n 3 "$LOG")
  [[ "$out" == *'top'* ]]
  [[ "$out" == *'10.0.0.1'* ]]
}

@test "[21] reports 5xx URLs" {
  out=$("$CMD" -n 3 "$LOG")
  [[ "$out" == *'/b'* || "$out" == *'/c'* ]]
}

@test "[21] allowlist diff finds IPs not in allowlist" {
  out=$("$CMD" --allowlist "$ALLOW" "$LOG")
  [[ "$out" == *'10.0.0.3'* ]]
  [[ "$out" != *'10.0.0.1'$'\n'* ]] || true   # allowed IPs not listed at the bottom
}

@test "[21] usage error on no LOG" {
  run "$CMD"
  assert_status 2
}
