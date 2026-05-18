#!/usr/bin/env bash
# FAILING EXERCISE — buggy pmap. FIVE bugs around concurrency + signal handling.

set -euo pipefail

# shellcheck source=../../lib/log.sh
source "$(dirname "$0")/../../lib/log.sh"

jobs=4
while getopts 'j:' opt; do
  case "$opt" in
    j) jobs=$OPTARG ;;
  esac
done
shift $((OPTIND - 1))

cmd=$1; shift

pids=()
for arg in "$@"; do
  "$cmd" "$arg" &
  pids+=($!)

  # Bound concurrency... but this is wrong.
  if [[ ${#pids[@]} -ge $jobs ]]; then
    wait $pids                                                    # BUG #1 (waits ALL not one; also expansion wrong)
    pids=()                                                       # BUG #2 (drops still-running tracking)
  fi
done

wait                                                              # BUG #3 (no error aggregation)

# No signal cleanup.                                              # BUG #4
# No exit-status propagation.                                     # BUG #5
echo "all done"
