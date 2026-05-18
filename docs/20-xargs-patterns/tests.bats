#!/usr/bin/env bats
# Tests for exercise 20.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/parallel-hash.sh"
  TREE="$TMPDIR_FOR_TEST/tree"
  mkdir -p "$TREE/sub"
  printf 'one\n'   > "$TREE/a"
  printf 'two\n'   > "$TREE/b"
  printf 'three\n' > "$TREE/sub/c"
  printf 'one\n'   > "$TREE/sub/a-dup"   # same content as a
}
teardown() { teardown_tmpdir; }

@test "[20] hashes every regular file" {
  out=$("$CMD" -j 2 "$TREE")
  [ "$(printf '%s\n' "$out" | wc -l)" -eq 4 ]
}

@test "[20] same content same hash" {
  out=$("$CMD" -j 2 "$TREE")
  # The setup creates exactly one duplicate pair (a == sub/a-dup);
  # expect exactly one duplicated hash, not "≥1".
  dup=$(printf '%s\n' "$out" | awk '{print $1}' | sort | uniq -d | wc -l)
  [ "$dup" -eq 1 ]
}

@test "[20] empty tree produces no output and exits 0" {
  mkdir -p "$TMPDIR_FOR_TEST/empty"
  run "$CMD" "$TMPDIR_FOR_TEST/empty"
  assert_status 0
  [ -z "$output" ]
}

@test "[20] handles filenames with spaces" {
  mkdir -p "$TMPDIR_FOR_TEST/sp"
  printf 'x\n' > "$TMPDIR_FOR_TEST/sp/a b.txt"
  out=$("$CMD" "$TMPDIR_FOR_TEST/sp")
  # Output line must contain BOTH a hex digest and the full filename
  # (a substring match alone could be satisfied by accidental content).
  [[ "$out" =~ ^[0-9a-f]{64}[[:space:]]+.*a\ b\.txt[[:space:]]*$ ]]
}

@test "[20] usage error on no DIR" {
  run "$CMD"
  assert_status 2
}
