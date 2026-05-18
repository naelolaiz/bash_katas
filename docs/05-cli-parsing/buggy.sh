#!/usr/bin/env bash
# FAILING EXERCISE — buggy filter-lines. FIVE bugs around getopts semantics.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

ci=0; invert=0; limit=0
while getopts 'ivn:' opt; do                                     # BUG #1 (no leading :)
  case "$opt" in
    i) ci=1 ;;
    v) invert=1 ;;
    n) limit=$OPTARG ;;
    *) echo "usage error" && exit 0 ;;                           # BUG #2 (exit 0 on usage error)
  esac
done
shift $OPTIND                                                     # BUG #3 (should be OPTIND-1)

pattern=$1
shift

# No FILE? read stdin. But if -t test fails, the script just hangs.
if [ $# -eq 0 ]; then
  files=(-)
else
  files=("$@")
fi

grep_opts=()
(( ci )) && grep_opts+=(-i)
(( invert )) && grep_opts+=(-v)

count=0
for f in ${files[@]}; do                                         # BUG #4 (unquoted array)
  while IFS= read -r line; do
    if echo "$line" | grep "${grep_opts[@]}" -q -e "$pattern"; then
      printf '%s\n' "$line"
      ((count++))
      (( limit > 0 && count >= limit )) && exit 0
    fi
  done < "$f"
done

# No matches?
(( count > 0 )) && exit 0                                        # BUG #5 (no exit 1 for no-match)
