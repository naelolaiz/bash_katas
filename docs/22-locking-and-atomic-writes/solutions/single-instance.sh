#!/usr/bin/env bash
# Reference: run a command, but only one instance at a time per LOCKFILE.
# Uses flock on an FD; lock is released automatically when the FD closes
# (on exit, kill, crash — all paths).

set -euo pipefail
# shellcheck source=../../../lib/log.sh
source "$(dirname "$0")/../../../lib/log.sh"

wait_sec=0
while [[ $# -gt 0 ]]; do
  case $1 in
    --wait) wait_sec=$2; shift 2 ;;
    --) shift; break ;;
    -*) die 2 "unknown option: $1" ;;
    *)  break ;;
  esac
done
(( $# >= 2 )) || die 2 'usage: single-instance [--wait SEC] LOCKFILE COMMAND [ARGS...]'
lockfile=$1; shift
(( $# > 0 )) || die 2 'COMMAND required'

# Open the lock file on a high FD; flock against the FD.
exec 200>"$lockfile"
if (( wait_sec > 0 )); then
  flock -w "$wait_sec" 200 || die 1 "could not acquire lock within ${wait_sec}s"
else
  flock -n 200 || die 1 'already running'
fi

# Optional: record our PID for monitoring tools.
printf '%d\n' $$ >&200

# Run the wrapped command; propagate its exit code.
"$@"
