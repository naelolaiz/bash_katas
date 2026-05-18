#!/usr/bin/env bats
# Tests for exercise 19.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/repo-find.sh"
  TREE="$TMPDIR_FOR_TEST/tree"
  mkdir -p "$TREE/src" "$TREE/node_modules" "$TREE/.git"
  : > "$TREE/src/a.go"
  : > "$TREE/src/b.go"
  : > "$TREE/node_modules/junk"
  : > "$TREE/.git/HEAD"
}
teardown() { teardown_tmpdir; }

@test "[19] lists source files" {
  out=$("$CMD" "$TREE")
  [[ "$out" == *'a.go'* ]]
  [[ "$out" == *'b.go'* ]]
}

@test "[19] prunes node_modules" {
  out=$("$CMD" "$TREE")
  [[ "$out" != *'junk'* ]]
}

@test "[19] prunes .git" {
  out=$("$CMD" "$TREE")
  [[ "$out" != *'HEAD'* ]]
}

@test "[19] --newer filters by mtime" {
  touch -d '2099-01-01' "$TREE/src/a.go"
  touch -d '2000-01-01' "$TREE/src/b.go"
  out=$("$CMD" --newer '2050-01-01' "$TREE")
  [[ "$out" == *'a.go'* ]]
  [[ "$out" != *'b.go'* ]]
}
