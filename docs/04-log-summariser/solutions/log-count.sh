#!/usr/bin/env bash
# Reference solution for exercise 4 (log-count).
# Primary implementation: bash associative array (zero forks).
#
# Trade-off: fastest under ~10^5 lines, no external dependency.
# For 10^6+ lines, hand off to `awk '{c[$2" "$3]++} END{for (k in c) print k, c[k]}'`
# — see the alternates below in comments.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

declare -A counts
malformed=0

while IFS= read -r line; do
  [[ -z $line ]] && continue
  read -r date level component _rest <<< "$line"
  # require a date-shaped first field, plus level + component
  if [[ ! $date =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ || -z $level || -z $component ]]; then
    err "malformed line: $line"
    malformed=$(( malformed + 1 ))
    continue
  fi
  key="$level $component"
  counts[$key]=$(( ${counts[$key]:-0} + 1 ))
done

if (( malformed > 0 )); then
  err "$malformed malformed line(s) skipped"
fi

for key in "${!counts[@]}"; do
  printf '%s %d\n' "$key" "${counts[$key]}"
done | LC_ALL=C sort

(( malformed == 0 )) || exit 1

# Alternative 1 (awk, one fork — recommended at scale):
#   awk '/^[0-9]/ { c[$2" "$3]++ } END { for (k in c) print k, c[k] }'
#
# Alternative 2 (coreutils pipeline — disk-friendly at unbounded scale):
#   awk '/^[0-9]/ { print $2, $3 }' \
#     | LC_ALL=C sort | uniq -c \
#     | awk '{ print $2, $3, $1 }'
