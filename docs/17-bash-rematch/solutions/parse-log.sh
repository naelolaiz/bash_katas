#!/usr/bin/env bash
# Reference: parse "<ts> [<LEVEL>] <component> id=<id> took=<n>ms"
# using [[ =~ ]] + BASH_REMATCH.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

# Unquoted RHS is the rule for =~.
re='^([0-9T:+-]+) \[(INFO|WARN|ERROR)\] ([^[:space:]]+) id=([^[:space:]]+) took=([0-9]+)ms$'

malformed=0
while IFS= read -r line; do
  if [[ $line =~ $re ]]; then
    # snapshot before any potential next =~
    caps=("${BASH_REMATCH[@]}")
    printf '%s\t%s\t%s\t%s\t%s\n' "${caps[1]}" "${caps[2]}" "${caps[3]}" "${caps[4]}" "${caps[5]}"
  else
    err "malformed: $line"
    malformed=$(( malformed + 1 ))
  fi
done

(( malformed == 0 )) || exit 1
