#!/usr/bin/env bash
# Reference: pmap -j JOBS COMMAND ARG... — bounded-concurrency runner.
# Returns the maximum exit code across all children (0 iff all succeeded).
# Kills outstanding children on SIGINT/SIGTERM.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

jobs=4
while getopts ':j:' opt; do
  case $opt in
    j) jobs=$OPTARG ;;
    *) die 2 'usage: pmap -j JOBS COMMAND ARG...' ;;
  esac
done
shift $((OPTIND - 1))
(( $# >= 1 )) || die 2 'COMMAND required'
cmd=$1; shift

pids=()
fail=0

# shellcheck disable=SC2317  # called via trap
cleanup() {
  trap - INT TERM EXIT
  if (( ${#pids[@]} > 0 )); then
    kill "${pids[@]}" 2>/dev/null || true
  fi
  wait 2>/dev/null || true
}
trap 'cleanup; exit 130' INT
trap 'cleanup; exit 143' TERM
trap cleanup EXIT

for arg in "$@"; do
  "$cmd" "$arg" &
  pids+=("$!")
  if (( ${#pids[@]} >= jobs )); then
    # block until any one finishes; capture status
    wait -n || fail=$?
  fi
done

# drain remaining
for pid in "${pids[@]}"; do
  wait "$pid" 2>/dev/null || fail=$?
done

exit "$fail"
