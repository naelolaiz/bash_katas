#!/usr/bin/env bats
# Tests for exercise 3.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  PE="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/pathinfo-pe.sh"
  CU="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/pathinfo-cu.sh"
  AWK="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/pathinfo-awk.sh"
}
teardown() { teardown_tmpdir; }

@test "[3] all three impls agree on /tmp/archive.tar.gz" {
  a=$("$PE"  /tmp/archive.tar.gz)
  b=$("$CU"  /tmp/archive.tar.gz)
  c=$("$AWK" /tmp/archive.tar.gz)
  [ "$a" = "$b" ]
  [ "$b" = "$c" ]
  [[ "$a" == *base=archive.tar.gz* ]]
  [[ "$a" == *dir=/tmp* ]]
  [[ "$a" == *stem=archive.tar* ]]
  [[ "$a" == *ext=gz* ]]
}

@test "[3] no extension: foo" {
  out=$("$PE" foo)
  [[ "$out" == *base=foo* ]]
  [[ "$out" == *ext=* ]]
  [[ "$out" != *ext=foo* ]]
}

@test "[3] leading-dot file: .hidden has no extension" {
  out=$("$PE" .hidden)
  [[ "$out" == *base=.hidden* ]]
  [[ "$out" == *stem=.hidden* ]]
  # ext should be empty
  echo "$out" | grep -E '^ext=$'
}

@test "[3] dot in parent but not basename: /foo.bar/baz" {
  out=$("$PE" /foo.bar/baz)
  [[ "$out" == *base=baz* ]]
  # ext must NOT pick up bar from the dirname
  [[ "$out" != *ext=bar* ]]
}

@test "[3] handles trailing slash" {
  run "$PE" /tmp/
  assert_status 0
  # All five labelled fields must be present in the output.
  for field in original dir base stem ext; do
    grep -qE "^${field}=" <<< "$output"
  done
}

@test "[3] usage error on no args" {
  run "$PE"
  assert_status 2
}
