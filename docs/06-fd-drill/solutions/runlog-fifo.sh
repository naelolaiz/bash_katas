#!/usr/bin/env bash
# Reference (FIFOs): POSIX-portable form — no process substitution, no
# `{fd}>` named-FD syntax. Uses `mkfifo` + background `tee` consumers.
# Trade-off: cleanup is manual (trap); slightly more code. Works in any
# POSIX shell with `mkfifo` available.

set -eu

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

quiet=0
while [ $# -gt 0 ]; do
  case $1 in
    --quiet) quiet=1; shift ;;
    --) shift; break ;;
    *)  break ;;
  esac
done

[ $# -ge 1 ] || { err 'usage: runlog-fifo [--quiet] LOGFILE CMD [ARGS...]'; exit 2; }
logfile=$1; shift
[ $# -gt 0 ] || { err 'command required'; exit 2; }

fifodir=$(mktemp -d)
trap 'rm -rf "$fifodir"' EXIT INT TERM
mkfifo "$fifodir/out" "$fifodir/err"

# Background tee consumers — one per stream.
if [ "$quiet" -eq 1 ]; then
  tee -a "$logfile" < "$fifodir/out" >/dev/null &
  tee -a "$logfile" < "$fifodir/err" >/dev/null &
else
  tee -a "$logfile" < "$fifodir/out" &
  sed -u 's/^/[stderr] /' < "$fifodir/err" | tee -a "$logfile" >&2 &
fi
tee1=$!

# Run the wrapped command; route its streams into the FIFOs.
"$@" > "$fifodir/out" 2> "$fifodir/err"
status=$?

wait "$tee1" 2>/dev/null || true
exit "$status"
