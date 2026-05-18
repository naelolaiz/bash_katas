#!/usr/bin/env bats
# Tests for exercise 14.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/perf-kata.sh"
  # tiny corpus: 4 distinct lowercased values
  cat > "$TMPDIR_FOR_TEST/in" <<'EOF'
a b APPLE rest
a b banana rest
a b apple rest
a b CHERRY rest
a b date rest
EOF
}
teardown() { teardown_tmpdir; }

@test "[14] all four modes return the same count" {
  for mode in naive builtin awk pipeline; do
    out=$("$CMD" --mode "$mode" "$TMPDIR_FOR_TEST/in")
    [ "$out" -eq 4 ]
  done
}

@test "[14] empty file -> 0" {
  : > "$TMPDIR_FOR_TEST/empty"
  for mode in builtin awk pipeline; do
    out=$("$CMD" --mode "$mode" "$TMPDIR_FOR_TEST/empty")
    [ "$out" -eq 0 ]
  done
}

@test "[14] unknown mode exits 2" {
  run "$CMD" --mode bogus "$TMPDIR_FOR_TEST/in"
  assert_status 2
}
