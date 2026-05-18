#!/usr/bin/env bats
# Tests for exercise 7.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  MANIFEST="$BATS_TEST_DIRNAME/solutions/manifest.sh"
  DIFF="$BATS_TEST_DIRNAME/solutions/manifest-diff.sh"

  mkdir -p "$TMPDIR_FOR_TEST/a" "$TMPDIR_FOR_TEST/b"
  printf 'one\n' > "$TMPDIR_FOR_TEST/a/x"
  printf 'two\n' > "$TMPDIR_FOR_TEST/a/y"
}
teardown() { teardown_tmpdir; }

@test "[7] manifest is reproducible (same input -> same output)" {
  a1=$("$MANIFEST" "$TMPDIR_FOR_TEST/a")
  a2=$("$MANIFEST" "$TMPDIR_FOR_TEST/a")
  [ "$a1" = "$a2" ]
}

@test "[7] identical trees diff exit 0" {
  cp -r "$TMPDIR_FOR_TEST/a"/. "$TMPDIR_FOR_TEST/b"/
  run "$DIFF" "$TMPDIR_FOR_TEST/a" "$TMPDIR_FOR_TEST/b"
  assert_status 0
}

@test "[7] different trees diff exit 1" {
  printf 'three\n' > "$TMPDIR_FOR_TEST/b/z"
  run "$DIFF" "$TMPDIR_FOR_TEST/a" "$TMPDIR_FOR_TEST/b"
  assert_status 1
}

@test "[7] missing arg exit 2" {
  run "$DIFF"
  assert_status 2
}

@test "[7] manifest skips mtime (cp -p target diffs to source)" {
  cp -r "$TMPDIR_FOR_TEST/a"/. "$TMPDIR_FOR_TEST/b"/
  touch -d '2020-01-01' "$TMPDIR_FOR_TEST/b/x"
  run "$DIFF" "$TMPDIR_FOR_TEST/a" "$TMPDIR_FOR_TEST/b"
  assert_status 0
}
