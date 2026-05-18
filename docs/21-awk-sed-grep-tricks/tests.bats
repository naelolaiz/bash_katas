#!/usr/bin/env bats
# Tests for exercise 21.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/log-analyse.sh"
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

@test "[21] reports top IPs in descending order" {
  out=$("$CMD" -n 3 "$LOG")
  # 10.0.0.1 appears twice; the others once each. Top result must be 10.0.0.1.
  top_line=$(echo "$out" | grep -E '^\s*[0-9]+\s+10\.' | head -1)
  echo "$top_line" | grep -qE '2\s+10\.0\.0\.1\b'
}

@test "[21] reports both 5xx URLs (/b and /c)" {
  out=$("$CMD" -n 5 "$LOG")
  # Both URLs that produced a 5xx must appear under the URLs section.
  [[ "$out" == *'/b'* ]]
  [[ "$out" == *'/c'* ]]
}

@test "[21] allowlist diff finds 10.0.0.3 and ONLY 10.0.0.3" {
  out=$("$CMD" --allowlist "$ALLOW" "$LOG")
  # Extract the "in log NOT in allowlist" section's IPs.
  diff_ips=$(echo "$out" | awk '/NOT in allowlist/{found=1; next} found && /^[0-9]/{print}')
  [ "$(echo "$diff_ips" | sort -u)" = '10.0.0.3' ]
}

@test "[21] usage error on no LOG" {
  run "$CMD"
  assert_status 2
}
