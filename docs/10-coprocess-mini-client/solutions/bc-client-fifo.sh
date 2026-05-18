#!/usr/bin/env bash
# Reference (FIFOs): POSIX-portable equivalent of the coproc-based client.
# Trade-off: no `coproc` keyword needed — runs under any POSIX shell with
# `mkfifo`. More boilerplate. FD management is explicit.

set -euo pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

timeout=5
while getopts ':t:' opt; do
  case $opt in
    t) timeout=$OPTARG ;;
    *) die 2 'usage: bc-client-fifo [-t TIMEOUT]' ;;
  esac
done

trap '' PIPE

fifodir=$(mktemp -d)
trap 'rm -rf "$fifodir"' EXIT

mkfifo "$fifodir/in" "$fifodir/out"

# Start bc, with stdin from the in-FIFO and stdout to the out-FIFO.
bc -l < "$fifodir/in" > "$fifodir/out" &
bcpid=$!

# Open both FIFOs on dedicated FDs so the shell holds them open across
# multiple write/read cycles. Open ORDER matters: open the writer first
# (so bc's reader doesn't block) — except bc is already blocked reading
# the FIFO, so opening writer 3 satisfies bc's open.
exec 3>"$fifodir/in"
exec 4<"$fifodir/out"

shutdown() {
  exec 3>&- || true
  wait "$bcpid" 2>/dev/null || true
}
trap shutdown EXIT

while IFS= read -r -p '> ' expr; do
  [[ -z $expr || $expr == quit ]] && break
  printf '%s\n' "$expr" >&3
  if ! IFS= read -r -t "$timeout" -u 4 answer; then
    err "timed out after ${timeout}s"
    continue
  fi
  printf '= %s\n' "$answer"
done

echo 'bye' >&2
