#!/usr/bin/env bash
# Reference: persistent bc -l client with timeout + crash recovery.
# Reads expressions from stdin; on EOF or "quit", shuts bc down cleanly.

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

timeout=5
while getopts ':t:' opt; do
  case $opt in
    t) timeout=$OPTARG ;;
    *) die 2 'usage: bc-client [-t TIMEOUT]' ;;
  esac
done

trap '' PIPE   # writes to dead bc become EPIPE, not SIGKILL

start_bc() { coproc BC { bc -l; }; }
start_bc

# shellcheck disable=SC2317  # called via trap
shutdown() {
  if [[ -n ${BC_PID:-} ]] && kill -0 "$BC_PID" 2>/dev/null; then
    kill "$BC_PID" 2>/dev/null || true
    wait "$BC_PID" 2>/dev/null || true
  fi
}
trap shutdown EXIT

while IFS= read -r -p '> ' expr; do
  [[ -z $expr || $expr == quit ]] && break

  if ! kill -0 "$BC_PID" 2>/dev/null; then
    err 'bc died; restarting'
    start_bc
  fi

  printf '%s\n' "$expr" >&"${BC[1]}"
  if ! read -r -t "$timeout" answer <&"${BC[0]}"; then
    err "timed out after ${timeout}s"
    continue
  fi
  printf '= %s\n' "$answer"
done

echo 'bye' >&2
