#!/usr/bin/env bash
# Reference: bash completion for exercise 5's filter-lines.
# Source from .bashrc:    source docs/12-programmable-completion/solutions/filter-lines-completion.sh

_filter_lines() {
  local cur prev all_opts seen opt
  cur=${COMP_WORDS[COMP_CWORD]}
  prev=${COMP_WORDS[COMP_CWORD - 1]:-}
  all_opts='-i -v -n --ignore-case --invert --limit --help'

  # value completion for known options
  case $prev in
    -n|--limit)
      # numeric arg — no suggestion
      COMPREPLY=()
      return
      ;;
  esac

  # --output=VALUE style
  if [[ $cur == --limit=* ]]; then
    COMPREPLY=()
    return
  fi

  if [[ ${cur:0:1} == - ]]; then
    # dedupe options already on the line
    local remaining=''
    for opt in $all_opts; do
      [[ " ${COMP_WORDS[*]} " == *" $opt "* ]] || remaining+=" $opt"
    done
    mapfile -t COMPREPLY < <(compgen -W "$remaining" -- "$cur")
  else
    # positional: pattern (no suggestion) then files
    mapfile -t COMPREPLY < <(compgen -f -- "$cur")
  fi
}
complete -F _filter_lines filter-lines
