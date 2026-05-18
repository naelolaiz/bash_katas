#!/usr/bin/env bats
# Tests for exercise 9.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/pmap.sh"
}
teardown() { teardown_tmpdir; }

@test "[9] runs command on each arg" {
  out=$("$CMD" -j 2 echo a b c | LC_ALL=C sort | tr '\n' ' ')
  [ "$out" = 'a b c ' ]
}

@test "[9] exit 0 when all children succeed" {
  run "$CMD" -j 4 true a b c d
  assert_status 0
}

@test "[9] exit non-zero when a child fails" {
  # pmap's API is `pmap CMD ARG...` — one invocation per ARG. Passing
  # `bash -c '...' a b c` would make pmap run `bash -c`, `bash '...'`,
  # `bash a`, ... separately. Use a small helper script instead.
  helper="$TMPDIR_FOR_TEST/fail-on-b.sh"
  cat > "$helper" <<'EOF'
#!/usr/bin/env bash
[[ $1 != b ]] || exit 5
EOF
  chmod +x "$helper"
  run "$CMD" -j 2 "$helper" a b c
  [ "$status" -ne 0 ]
}

@test "[9] usage error on no command" {
  run "$CMD" -j 4
  assert_status 2
}

@test "[9] -j 1 runs serially (still works)" {
  out=$("$CMD" -j 1 echo x y z | LC_ALL=C sort | tr '\n' ' ')
  [ "$out" = 'x y z ' ]
}
