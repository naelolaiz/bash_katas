#!/usr/bin/env bats
# Tests for exercise 12.

load ../../lib/test_helpers

setup() {
  setup_tmpdir
  COMP="$BATS_TEST_DIRNAME/solutions/filter-lines-completion.sh"
}
teardown() { teardown_tmpdir; }

@test "[12] completion file is sourceable" {
  bash -c "source '$COMP'"
}

@test "[12] completion suggests known long options" {
  out=$(bash <<EOF
    source "$COMP"
    COMP_WORDS=(filter-lines --i)
    COMP_CWORD=1
    _filter_lines
    printf '%s\n' "\${COMPREPLY[@]}"
EOF
)
  [[ "$out" == *'--ignore-case'* || "$out" == *'--invert'* ]]
}

@test "[12] already-supplied option is not suggested again" {
  out=$(bash <<EOF
    source "$COMP"
    COMP_WORDS=(filter-lines --quiet --)
    COMP_CWORD=2
    _filter_lines
    printf '%s\n' "\${COMPREPLY[@]}"
EOF
)
  [[ "$out" != *'--quiet'* ]]
}
