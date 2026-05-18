#!/usr/bin/env bats
# Tests for exercise 25.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  CMD="$BATS_TEST_DIRNAME/solutions/template.sh"
  TPL="$TMPDIR_FOR_TEST/t.tmpl"
}
teardown() { teardown_tmpdir; }

@test "[25] substitutes \$VAR and \${VAR}" {
  printf 'hello $NAME, age ${AGE}\n' > "$TPL"
  NAME=alice AGE=30 out=$(NAME=alice AGE=30 "$CMD" "$TPL")
  [[ "$out" == 'hello alice, age 30' ]]
}

@test "[25] :- default applies when var unset" {
  printf 'role=${ROLE:-guest}\n' > "$TPL"
  out=$("$CMD" "$TPL")
  [ "$out" = 'role=guest' ]
}

@test "[25] does NOT execute \$(...) from the template" {
  printf 'output: $(rm -rf /)\n' > "$TPL"
  out=$("$CMD" "$TPL")
  # the template should appear verbatim because $(...) is not a valid VAR pattern
  [[ "$out" == *'$(rm -rf /)'* ]]
}

@test "[25] --strict errors on unset variable" {
  printf 'has $REQUIRED\n' > "$TPL"
  run "$CMD" --strict "$TPL"
  assert_status 2
}

@test "[25] usage error on no FILE" {
  run "$CMD"
  assert_status 2
}
