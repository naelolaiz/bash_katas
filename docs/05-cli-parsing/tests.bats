#!/usr/bin/env bats
# Tests for exercise 5.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/filter-lines.sh"
  cat > "$TMPDIR_FOR_TEST/in.txt" <<'EOF'
apple
Banana
cherry
apricot
EOF
}
teardown() { teardown_tmpdir; }

@test "[5] basic match" {
  run "$CMD" 'a' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 0
  assert_output_contains 'apple'
}

@test "[5] -i case-insensitive" {
  run "$CMD" -i 'b' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 0
  assert_output_contains 'Banana'
}

@test "[5] -v invert" {
  run "$CMD" -v 'a' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 0
  assert_output_contains 'cherry'
}

@test "[5] -n limit stops after N matches" {
  run "$CMD" -n 2 'a' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 0
  [ "$(wc -l <<< "$output")" -eq 2 ]
}

@test "[5] exit 1 when no matches" {
  run "$CMD" 'zzzz' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 1
}

@test "[5] exit 2 on no args" {
  run "$CMD"
  assert_status 2
}

@test "[5] exit 2 on unknown option" {
  run "$CMD" -z 'pat' "$TMPDIR_FOR_TEST/in.txt"
  assert_status 2
}
