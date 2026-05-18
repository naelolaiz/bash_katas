#!/usr/bin/env bash
# Reference (xargs -P): simplest form. One xargs invocation does the pool.
# Trade-off: output is interleaved when commands produce multi-line output;
# exit status follows xargs's "123 if any child failed" convention rather
# than the max exit code. Ship this when the workload is straightforward.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

jobs=4
while getopts ':j:' opt; do
  case $opt in
    j) jobs=$OPTARG ;;
    *) die 2 'usage: pmap-xargs -j JOBS COMMAND ARG...' ;;
  esac
done
shift $((OPTIND - 1))
(( $# >= 1 )) || die 2 'COMMAND required'
cmd=$1; shift

# NUL-safe input to xargs; one item per invocation; -P workers in parallel.
# `-r` (no-run-if-empty) avoids running the command with zero args.
printf '%s\0' "$@" | xargs -0r -n1 -P "$jobs" -- "$cmd"
