#!/usr/bin/env bats
# Tests for exercise 15.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="${KATA_SOL_DIR:-$BATS_TEST_DIRNAME/solutions}/repo-janitor.sh"
  TREE="$TMPDIR_FOR_TEST/tree"
  mkdir -p "$TREE/sub" "$TREE/node_modules" "$TREE/.cache"
  printf 'same\n' > "$TREE/a"
  printf 'same\n' > "$TREE/sub/dup"
  printf 'broken-link target\n' > "$TREE/will-be-removed"
  ln -s ./will-be-removed "$TREE/link"
  rm "$TREE/will-be-removed"
  : > "$TREE/node_modules/junk"
}
teardown() { teardown_tmpdir; }

@test "[15] dry-run by default does NOT delete anything" {
  run "$CMD" "$TREE"
  [ "$status" -eq 0 ] || [ "$status" -eq 1 ]
  [ -e "$TREE/a" ]
  [ -e "$TREE/sub/dup" ]
  [ -d "$TREE/node_modules" ]
}

@test "[15] dry-run reports a duplicate" {
  run "$CMD" "$TREE"
  assert_output_contains 'duplicate'
}

@test "[15] dry-run reports broken symlink" {
  run "$CMD" "$TREE"
  assert_output_contains 'broken-symlink'
}

@test "[15] dry-run reports junk directory" {
  run "$CMD" "$TREE"
  assert_output_contains 'junk-dir'
}

@test "[15] --json output is parseable per-line" {
  if ! command -v jq >/dev/null; then skip 'jq not installed'; fi
  # repo-janitor exits 1 when there are findings; that's expected here.
  out=$("$CMD" --json "$TREE") || true
  while IFS= read -r line; do
    [[ -z $line ]] && continue
    echo "$line" | jq -e '.category' >/dev/null
  done <<< "$out"
}

@test "[15] usage error on no DIR" {
  run "$CMD"
  assert_status 2
}
