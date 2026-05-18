#!/usr/bin/env bats
# Tests for exercise 18.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/count-lines.sh"
  FILE="$TMPDIR_FOR_TEST/in"
  printf 'a\nb\nc\n' > "$FILE"
}
teardown() { teardown_tmpdir; }

@test "[18] wc method" {
  out=$("$CMD" --method wc "$FILE")
  [ "$out" = '3' ]
}

@test "[18] mapfile method" {
  out=$("$CMD" --method mapfile "$FILE")
  [ "$out" = '3' ]
}

@test "[18] while method" {
  out=$("$CMD" --method while "$FILE")
  [ "$out" = '3' ]
}

@test "[18] awk method" {
  out=$("$CMD" --method awk "$FILE")
  [ "$out" = '3' ]
}

@test "[18] last line without newline counted" {
  printf 'a\nb\nc' > "$FILE"   # no trailing newline
  out=$("$CMD" --method while "$FILE")
  [ "$out" = '3' ]
}

@test "[18] unknown method exits 2" {
  run "$CMD" --method bogus "$FILE"
  assert_status 2
}
