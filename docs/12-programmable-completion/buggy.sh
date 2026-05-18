#!/usr/bin/env bash
# FAILING EXERCISE — buggy completion. FIVE bugs in COMPREPLY/compgen usage.
# This is the completion function itself, not a script to run.
# Source-load it: `source docs/12-programmable-completion/buggy.sh`
# Then `complete -F _filter_lines filter-lines` (already done at bottom).

# shellcheck disable=SC2120,SC2178   # this is a completion handler

_filter_lines() {
  local cur prev
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD-1]}

  # complete option args
  if [[ $prev == --output ]]; then
    COMPREPLY=( $(compgen -f $cur) )                              # BUG #1 (unquoted; no --)
    return
  fi

  # complete options when current word starts with -
  if [[ ${cur:0:1} == - ]]; then
    COMPREPLY=( $(compgen -W '--help --quiet --verbose --output' $cur) )  # BUG #2 (no --)
    return
  fi

  # otherwise complete files
  COMPREPLY=( $(ls $cur*) )                                       # BUG #3 (ls antipattern)

  # no dedupe of already-supplied options                         # BUG #4
  # no support for --output=FILE form                             # BUG #5
}
complete -F _filter_lines filter-lines
