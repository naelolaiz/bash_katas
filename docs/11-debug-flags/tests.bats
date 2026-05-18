#!/usr/bin/env bats
# Tests for exercise 11.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/debug-runner.sh"
}
teardown() { teardown_tmpdir; }

@test "[11] propagates wrapped command's exit code" {
  run "$CMD" -- bash -c 'exit 7'
  assert_status 7
}

@test "[11] --quiet suppresses log lines" {
  run "$CMD" --quiet -- echo hello
  # stdout has the command's output; stderr should be empty
  [ "$output" = 'hello' ]
}

@test "[11] --verbose emits log to stderr (not stdout)" {
  out=$("$CMD" --verbose -- echo data 2>/dev/null)
  [ "$out" = 'data' ]
}

@test "[11] --dry-run does not execute" {
  marker="$TMPDIR_FOR_TEST/marker"
  "$CMD" --dry-run -- touch "$marker" 2>/dev/null || true
  [ ! -e "$marker" ]
}

@test "[11] --dry-run emits the command via printf %q" {
  out=$("$CMD" --dry-run -- echo "a b" 2>&1 >/dev/null)   # capture stderr only
  [[ "$out" == *'DRY:'* ]]
  [[ "$out" == *"'a b'"* || "$out" == *'a\ b'* ]]
}

@test "[11] usage error on no args" {
  run "$CMD"
  assert_status 2
}
