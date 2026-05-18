#!/usr/bin/env bash
# Reference solution for exercise 6 (runlog).
# Tees stdout AND stderr to the same LOGFILE while keeping them visible
# on the terminal, and propagates the wrapped command's real exit status.

set -euo pipefail
set -o pipefail

# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

quiet=0
trace=0
while [[ $# -gt 0 ]]; do
  case "$1" in
    --quiet) quiet=1; shift ;;
    --trace) trace=1; shift ;;
    --)      shift; break ;;
    -*)      err "unknown option: $1"; exit 2 ;;
    *)       break ;;
  esac
done

(( $# >= 1 )) || { err 'usage: runlog [--quiet] [--trace] LOGFILE CMD [ARGS...]'; exit 2; }
logfile=$1; shift
(( $# > 0 )) || { err 'command required'; exit 2; }

if (( trace )); then
  exec {tracefd}>>"$logfile.trace"
  BASH_XTRACEFD=$tracefd
  PS4='+ ${BASH_SOURCE##*/}:${LINENO}: '
  set -x
fi

# Pick the tee destinations based on --quiet.
if (( quiet )); then
  out_dest='/dev/null'
  err_dest='/dev/null'
else
  out_dest='/dev/tty'
  err_dest='/dev/tty'
fi

# Use process substitution to split, prefix stderr, and tee both to the log.
"$@" \
  >  >(tee -a "$logfile" > "$out_dest") \
  2> >(sed -u 's/^/[stderr] /' | tee -a "$logfile" > "$err_dest")

status=${PIPESTATUS[0]}
exit "$status"
