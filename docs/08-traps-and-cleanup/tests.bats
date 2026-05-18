#!/usr/bin/env bats
# Tests for exercise 8.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/safe-edit.sh"
  FILE="$TMPDIR_FOR_TEST/target"
  printf 'original\n' > "$FILE"
  chmod 0644 "$FILE"
}
teardown() { teardown_tmpdir; }

@test "[8] successful command replaces original" {
  "$CMD" "$FILE" bash -c 'echo modified > "$1"' _
  [ "$(cat "$FILE")" = 'modified' ]
}

@test "[8] failing command leaves original untouched" {
  run "$CMD" "$FILE" bash -c 'echo changed > "$1"; exit 7' _
  assert_status 7
  [ "$(cat "$FILE")" = 'original' ]
}

@test "[8] preserves mode" {
  chmod 0640 "$FILE"
  "$CMD" "$FILE" bash -c 'echo modified > "$1"' _
  perms=$(stat -c '%a' "$FILE")
  [ "$perms" = '640' ]
}

@test "[8] tmpdir cleaned up on normal exit" {
  "$CMD" "$FILE" bash -c 'echo m > "$1"' _
  # no leftover .safe-edit.* directories in parent
  count=$(find "$(dirname "$FILE")" -maxdepth 1 -name '.safe-edit.*' | wc -l)
  [ "$count" -eq 0 ]
}

@test "[8] usage error on no args" {
  run "$CMD"
  assert_status 2
}

@test "[8] missing FILE error" {
  run "$CMD" /no/such/path true
  assert_status 2
}
